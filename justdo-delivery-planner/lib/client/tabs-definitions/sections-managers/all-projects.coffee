helpers = GridData.helpers

NaturalCollectionSubtreeSection = GridData.sections_managers.NaturalCollectionSubtreeSection

AllProjectsSection = (grid_data_obj, section_root, section_obj, options) ->
  GridData.sections_managers.GridDataSectionManager.call @, grid_data_obj, section_root, section_obj, options

  @member_id = options.member_id

  @_member_tasks_object_computation = null # Will be set on first call to @_each
  @_member_tasks_object = null # Will be set by @_member_tasks_object_computation

  return @

Util.inherits AllProjectsSection, GridData.sections_managers.GridDataSectionManager

_.extend AllProjectsSection.prototype,
  terms_ids: ["short-term", "mid-term", "long-term", "unassigned-term"]

  _isPathExist: (relative_path) ->
    # Note, we can assume relative_path is not "/"

    path_array = helpers.getPathArray(relative_path)

    term_id = path_array.shift()

    if term_id not in @terms_ids
      return false

    if path_array.length == 0
      # Top level path, is a user in this project, return true
      return true

    parent_path = "#{@section_root_no_trailing_slash}/#{term_id}/"

    # Forward the check
    return @_forwardActionToNaturalCollectionSubtreeSection parent_path, term_id, (natural_col_sub_tree_section) ->
      if natural_col_sub_tree_section._isPathExist(helpers.joinPathArray(path_array))
        return true

      return false

  _each: (relative_path, options, iteratee) ->
    # If relative_path != "/"
    #
    # forward handling
    if relative_path != "/"
      path_item_id = helpers.getPathItemId(relative_path)

      path_array = helpers.getPathArray(relative_path)
      term_id = path_array.shift()

      parent_relative_path = "/#{term_id}/"
      parent_abs_path = "#{@section_root_no_trailing_slash}#{parent_relative_path}"

      return @_forwardActionToNaturalCollectionSubtreeSection parent_abs_path, term_id, (natural_col_sub_tree_section) ->
        return natural_col_sub_tree_section._each(helpers.joinPathArray(path_array), options, iteratee)

    # If relative_path == "/"
    
    # Traverse the section's top level items

    #
    # In the first time that @_each is getting called (we assume that it is the
    # section build phase), we set up a computation that will trigger a rebuild
    # when the list of members with direct tasks changes.
    #

    if not @_member_tasks_object_computation?
      @_member_tasks_object_computation = Tracker.autorun (c) =>
        user_tasks_ids_by_term = @getUserTasksIdsByTerm()

        if @_member_tasks_object_computation? and
            EJSON.stringify(user_tasks_ids_by_term) != EJSON.stringify(@_member_tasks_object)
          @grid_data._set_need_rebuild()

          c.stop()

          return

        @_member_tasks_object = user_tasks_ids_by_term

    return_value = true
    for term_id in @terms_ids
      task_title = JustdoHelpers.ucFirst term_id.replace("-term", "") + " Term"

      parent_relative_path = "/#{term_id}/"
      parent_abs_path = "#{@section_root_no_trailing_slash}#{parent_relative_path}"

      expand_state = undefined
      step_into = true
      if options.expand_only
        # According to @_each() definition, expand_state is defined only if
        # expand_only is set to true.

        if term_id not of @_member_tasks_object
          expand_state = -1
          step_into = false
        else
          expand_state = @_inExpandedPaths(parent_relative_path)

          if expand_state == 0
            step_into = false

      iteratee_ret = iteratee(
        @section_obj,
        "workload-term-header",
        {_id: term_id, title: task_title},
        parent_abs_path,
        expand_state
      )

      if iteratee_ret == -2
        # Iteratee ask to stop immediately
        return false

      if iteratee_ret == -1
        # Don't step into items 
        continue

      if step_into
        @_forwardActionToNaturalCollectionSubtreeSection parent_abs_path, term_id, (natural_col_sub_tree_section) ->
          if not natural_col_sub_tree_section._each("/", options, iteratee)
            return_value = false

    return return_value

  _forwardActionToNaturalCollectionSubtreeSection: (parent_abs_path, term_id, cb) ->
    # cb will get a NaturalCollectionSubtreeSection initialized with the
    # correct argument according to @ state and the requested parent_abs_path
    # cb(natural_col_sub_tree_section)
    #
    # cb is called with @ set to the AllProjectsSection object
    #
    # _forwardActionToNaturalCollectionSubtreeSection also takes care of destroying
    # the NaturalCollectionSubtreeSection properly after cb finish execution.

    # Returns the value returned by the cb()

    # Forward handling to NaturalCollectionSubtreeSection

    natural_col_sub_tree_section =
      new NaturalCollectionSubtreeSection(
            @grid_data,
            parent_abs_path,
            @section_obj,
            {
              rootItems: => @_member_tasks_object[term_id] or {}
              root_items_sort_by: (item) -> item.priority * -1
              itemsTypesAssigner: (item_obj, relative_path) ->
                if GridData.helpers.getPathLevel(relative_path) == 0
                  return "workload-term-task"

                return null
            }
          )

    cb_return_value = cb.call(@, natural_col_sub_tree_section)

    # Note, we can safely destroy as soon as we are finish with this sub section
    # since we don't set rootItems() methods (that runs in a computation, and
    # affect the tree rebuild after first each).
    # If that wasn't the case, we'd have to wait for the @destroy() of the
    # AllProjectsSection and only then destroy all the sub sections
    # together.
    natural_col_sub_tree_section.destroy()

    return cb_return_value

  getUserTasksIdsByTerm: ->
    term_field_id = JustdoWorkloadPlanner.term_field_id

    query =
      $or: [
        { pending_owner_id: @member_id },
        { owner_id: @member_id }
      ]
    query[term_field_id] = { $ne: null }
    query["state"] = {$nin: ["done", "will-not-do"]}

    if (project_id = APP.modules?.project_page?.curProj()?.id)?
      query.project_id = project_id

    query_fields_option =
      _id: 1
    query_fields_option[term_field_id] = 1

    res = {}
    APP.collections.Tasks.find(query, {sort: {priority: -1}, fields: query_fields_option}).forEach (task_doc) =>
      task_term_id = task_doc[term_field_id]

      if task_term_id not of res
        res[task_term_id] = {}

      res[task_term_id][task_doc._id] = true

      return

    return res

  destroy: ->
    if @_member_tasks_object_computation?
      @_member_tasks_object_computation.stop()

    return

GridData.installSectionManager("AllProjectsSection", AllProjectsSection)
