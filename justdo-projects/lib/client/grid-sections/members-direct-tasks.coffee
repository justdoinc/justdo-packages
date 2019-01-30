helpers = GridData.helpers

NaturalCollectionSubtreeSection = GridData.sections_managers.NaturalCollectionSubtreeSection

MembersDirectTasksSection = (grid_data_obj, section_root, section_obj, options) ->
  GridData.sections_managers.GridDataSectionManager.call @, grid_data_obj, section_root, section_obj, options

  @_members_tasks_ids_computation = null # Will be set on first call to @_each

  return @

Util.inherits MembersDirectTasksSection, GridData.sections_managers.GridDataSectionManager

_.extend MembersDirectTasksSection.prototype,
  direct_tasks_prefix: "direct:"

  _isPathExist: (relative_path) ->
    # Note, we can assume relative_path is not "/"

    path_array = helpers.getPathArray(relative_path)

    direct_task_parent_id = path_array.shift()

    if direct_task_parent_id.substr(0, @direct_tasks_prefix.length) != @direct_tasks_prefix
      # Doesn't conform with direct tasks parents ids format, can't be a root item of this section
      return false

    if not @grid_data.tree_structure[direct_task_parent_id]?
      # If not a parent of any item, can't be a direct task (note, grid-data-core, takes care of
      # removing empty parents from tree_structure, no need to worry about this case)

      # Note, that this test alone will return true for any item that is a parent in the tree
      # and not only for direct tasks parents, hence we check also for the id format.
      return false

    if path_array.length == 0
      # Top level path, is a direct task parent
      return true

    direct_task_parent_path = "#{@section_root_no_trailing_slash}/#{direct_task_parent_id}/"

    # Forward the check
    return @_forwardActionToNaturalCollectionSubtreeSection direct_task_parent_path, (natural_col_sub_tree_section) ->
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
      direct_task_parent_id = path_array.shift()

      direct_tasks_parent_relative_path = "/#{direct_task_parent_id}/"
      direct_tasks_parent_abs_path = "#{@section_root_no_trailing_slash}#{direct_tasks_parent_relative_path}"

      return @_forwardActionToNaturalCollectionSubtreeSection direct_tasks_parent_abs_path, (natural_col_sub_tree_section) ->
        return natural_col_sub_tree_section._each(helpers.joinPathArray(path_array), options, iteratee)

    # If relative_path == "/"
    #
    # Traverse the section's top level items

    #
    # In the first time that @_each is getting called (we assume that it is the
    # section build phase), we set up a computation that will trigger a rebuild
    # when the list of members with direct tasks changes.
    #
    project_members_direct_tasks_ids = null
    if not @_members_tasks_ids_computation?
      @_members_tasks_ids_computation = Tracker.autorun (c) =>
        new_project_members_direct_tasks_ids = @_getMembersDirectTasksIds()

        if @_members_tasks_ids_computation? and
            not _.isEqual(new_project_members_direct_tasks_ids, project_members_direct_tasks_ids)
          @grid_data._set_need_rebuild()

          c.stop()

          return

        project_members_direct_tasks_ids = new_project_members_direct_tasks_ids
    else
      project_members_direct_tasks_ids = @_getMembersDirectTasksIds()

    return_value = true
    for direct_task_parent_id, ignore of project_members_direct_tasks_ids
      user_doc = Meteor.users.findOne(direct_task_parent_id.substr(@direct_tasks_prefix.length))

      task_title = "Unknown user id"
      if user_doc?
        task_title = JustdoHelpers.displayName(user_doc) + " Direct Tasks"

      direct_tasks_parent_relative_path = "/#{direct_task_parent_id}/"
      direct_tasks_parent_abs_path = "#{@section_root_no_trailing_slash}#{direct_tasks_parent_relative_path}"

      expand_state = undefined
      step_into = true
      if options.expand_only
        # According to @_each() definition, expand_state is defined only if
        # expand_only is set to true.

        # Note, @_inExpandedPaths() expects provided direct_tasks_parent_relative_path to have childrens.
        # In MembersDirectTasksSection we print only direct tasks headers
        # for members that have direct tasks, hence we know for sure all
        # items has childrens and @_inExpandedPaths() will work properly.
        expand_state = @_inExpandedPaths(direct_tasks_parent_relative_path)

        if expand_state == 0
          step_into = false

      iteratee_ret = iteratee(
        @section_obj,
        "member-direct-tasks-header",
        {_id: direct_task_parent_id, title: task_title},
        direct_tasks_parent_abs_path,
        expand_state
      )

      if iteratee_ret == -2
        # Iteratee ask to stop immediately
        return false

      if iteratee_ret == -1
        # Don't step into items 
        continue

      if step_into
        @_forwardActionToNaturalCollectionSubtreeSection direct_tasks_parent_abs_path, (natural_col_sub_tree_section) ->
          if not natural_col_sub_tree_section._each("/", options, iteratee)
            return_value = false

    return return_value

  _forwardActionToNaturalCollectionSubtreeSection: (direct_task_abs_path, cb) ->
    # cb will get a NaturalCollectionSubtreeSection initialized with the
    # correct argument according to @ state and the requested direct_task_abs_path
    # cb(natural_col_sub_tree_section)
    #
    # cb is called with @ set to the MembersDirectTasksSection object
    #
    # _forwardActionToNaturalCollectionSubtreeSection also takes care of destroying
    # the NaturalCollectionSubtreeSection properly after cb finish execution.

    # Returns the value returned by the cb()

    # Forward handling to NaturalCollectionSubtreeSection

    natural_col_sub_tree_section =
      new NaturalCollectionSubtreeSection(
            @grid_data,
            direct_task_abs_path,
            @section_obj,
            {
              tree_root_item_id: helpers.getPathItemId(direct_task_abs_path)
            }
          )

    cb_return_value = cb.call(@, natural_col_sub_tree_section)

    # Note, we can safely destroy as soon as we are finish with this sub section
    # since we don't set rootItems() methods (that runs in a computation, and
    # affect the tree rebuild after first each).
    # If that wasn't the case, we'd have to wait for the @destroy() of the
    # MembersDirectTasksSection and only then destroy all the sub sections
    # together.
    natural_col_sub_tree_section.destroy()

    return cb_return_value

  _getMemberDirectTaskParentId: (project_members_id) ->
    return @direct_tasks_prefix + project_members_id

  _getMembersDirectTasksIds: ->
    # Returns an object of the form {direct_task_id: true, ...}
    # for all the project members we have direct tasks for, not including
    # the logged-in user.
    #
    # Fail silently from user perspective: returns an empty object
    # on error (console logs an error)

    current_member_id = Meteor.userId()

    if not (current_project = APP.modules.project_page.curProj())?
      console.error "MembersDirectTasksSection: Couldn't find current project"

      return {}

    current_member_id = Meteor.userId()

    project_members_ids = current_project.getMembersIds()

    project_members_direct_tasks_ids = {}
    for project_members_id in project_members_ids
      if project_members_id is current_member_id
        # Skip current member, we show his direct tasks in
        # MyDirectTasksSection section
        continue

      direct_task_parent_id = @_getMemberDirectTaskParentId(project_members_id)
      if @grid_data.tree_structure[direct_task_parent_id]?
        project_members_direct_tasks_ids[direct_task_parent_id] = true

    return project_members_direct_tasks_ids

  destroy: ->
    # Upon destroy, stop @_members_tasks_ids_computation, in case one was set
    if @_members_tasks_ids_computation?
      @_members_tasks_ids_computation.stop()

GridData.installSectionManager("MembersDirectTasksSection", MembersDirectTasksSection)
