_.extend JustdoDeliveryPlanner.prototype,
  _immediateInit: ->
    @setup_projects_collection_plugin_tracker = null
    @_setupProjectsCollectionPlugin()

    @setup_projects_collection_features_tracker = null
    @_setupProjectsCollectionFeaturesTracker()

    return

  _deferredInit: ->
    if @destroyed
      return

    @registerTabSwitcherSection() # Moved out of setupCustomFeatureMaintainer once Projects became a builtin feature

    @setupCustomFeatureMaintainer()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    return

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoDeliveryPlanner.project_custom_feature_id,

      installer: =>
        return

      destroyer: =>
        return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  registerTabSwitcherSection: ->
    self = @

    isInstalledOnCurrentProject = ->
      # cur_project = APP.modules.project_page.curProj()

      # if not cur_project?
      #   return

      # return cur_project.isCustomFeatureEnabled(JustdoDeliveryPlanner.project_custom_feature_id)
      return true # In Jul 2nd 2020 projects became a built-in feature

    getAllJustdoActiveProjectsSortedByProjectName = ->
      return APP.justdo_delivery_planner.getKnownProjects(JD.activeJustdo({_id: 1})?._id, {active_only: true, sort_by: {title: 1}}, Meteor.userId())

    APP.modules.project_page.tab_switcher_manager.registerSectionItem "main", "projects",
      position: 300
      data:
        label: "Projects"
        label_i18n: "tab_switcher_projects_label"
        tab_id: "jdp-all-projects"

        icon_type: "feather"
        icon_val: "briefcase"
      listingCondition: isInstalledOnCurrentProject
    APP.modules.project_page.tab_switcher_manager.registerSection "projects",
      position: 350
      data:
        label: "Projects"
        label_i18n: "tab_switcher_projects_section_label"

        itemsGenerator: ->
          res = []

          for project_task_doc, i in getAllJustdoActiveProjectsSortedByProjectName()
            res.push
              _id: project_task_doc._id

              label: project_task_doc.title
              tab_id: "sub-tree"

              icon_type: "feather"
              icon_val: "briefcase"

              tab_sections_state:
                global:
                  "root-item": project_task_doc._id

          return res

      listingCondition: ->
        if isInstalledOnCurrentProject() and getAllJustdoActiveProjectsSortedByProjectName().length > 0
          return true

    position = 200
    for projects_collection_type in @getSupportedProjectsCollectionTypes()
      type_id = projects_collection_type.type_id

      APP.modules.project_page.tab_switcher_manager.registerSectionItem "main", "projects_collection_#{type_id}",
        position: position
        data:
          label: TAPi18n.__ projects_collection_type.type_label_plural_i18n, {}, JustdoI18n.default_lang
          label_i18n: projects_collection_type.type_label_plural_i18n
          tab_id: "jdp-projects-collection"

          icon_type: "feather"
          icon_val: projects_collection_type.type_icon.val

          tab_sections_state:
            global:
              "projects-collection-type": type_id
        listingCondition: =>
          return @isProjectsCollectionEnabled()
          
        position += 10

    installTabsOnGcm = (gcm) =>
      if gcm.destroyed == true
        # Nothing to do

        return

      if gcm._delivery_planner_tabs_installed?
        # Already installed on this gcm (can happen when the plugin enable/disable mode is toggled)

        return

      for tab in @getTabsDefinitions()
        gcm.addTab tab.id, tab.options

      gcm._delivery_planner_tabs_installed = true

      return

    # We attempt to install both when the "grid-control-mux-created" event is triggered,
    # but also immediately, if we find that a gcm exists already.
    #
    # The event is to have the tab installed immediately after the grid control mux is created
    # (to have it available for urls that has it as target).
    #
    # The immediate install that comes after, is for case plugin been enabled after the mux
    # been already created.
    #
    # Note, installTabsOnGcm have protection from duplicate installation.
    if (gcm = APP.modules.project_page.grid_control_mux.get())?
      installTabsOnGcm(gcm)

    APP.modules.project_page.on "grid-control-mux-created", gridControlMuxCreatedCb = (gcm) ->
      installTabsOnGcm(gcm)

      return

    return

  unregisterTabSwitcherSection: ->
    APP.modules.project_page.tab_switcher_manager.unregisterSectionItem "main", "projects"

    APP.modules.project_page.tab_switcher_manager.unregisterSection "projects"

    return

  excludeProjectsCauseCircularChain: (project_tasks, task_id_to_be_added) ->
    grid_data_core = APP.modules.project_page?.mainGridControl()?._grid_data?._grid_data_core

    if not grid_data_core? or not task_id_to_be_added?
      return project_tasks

    # Remove projects that are tasks to which we can't be assigned as a child due to circular
    # chain.
    project_tasks = _.filter project_tasks, (task) ->
      ancestors = grid_data_core.getAllItemsKnownAncestorsIdsObj [task._id]
      return not ancestors[task_id_to_be_added]?

    return project_tasks

  getAncestorProjectsOfTask: (task_id, gc) ->
    # Note: This is a CLIENT side method. As such, only the tasks visible to the current user is considered.
    # Returns an object with the following structure:
    # {
    #   "/uYRDib7DHETEDbswF/DATQeZkGPKrejewcA/HTynggq3HP2uABW5j/": {
    #     projects: [item_doc_of_DATQeZkGPKrejewcA, item_doc_of_uYRDib7DHETEDbswF, ...]
    #   }
    # }
    # Where:
    # - `HTynggq3HP2uABW5j` is the immediate parent of the provided `task_id`
    # - The `projects` array is sorted by the order of the ancestor path, from closest ancestor to the farthest.
    if not gc?
      gc = APP.modules.project_page?.mainGridControl()
    
    grid_data_core = gc._grid_data?._grid_data_core

    if (not gc?) or (not grid_data_core?)
      return []
    
    # Note, that we use grid_data_core's getAllCollectionPaths and not gd.getAllCollectionItemIdPaths
    # since we want to be able to work with custom gc's which their gd might not reflect the natural
    # tree derived from the tasks collections parents.
    ancestors_paths = grid_data_core.getAllCollectionPaths task_id
    ret = {}

    for ancestor_path in ancestors_paths
      path_arr = GridData.helpers.getPathArray ancestor_path
      # The last item in the path array is the task itself, so we need to remove it
      path_arr.pop()
      # Reverse the path array to check from the closest ancestor to the root
      path_arr.reverse()

      for item_id in path_arr
        item_doc = grid_data_core.items_by_id[item_id]
        if @isTaskObjProject item_doc
          if not ret[ancestor_path]?
            ret[ancestor_path] = 
              projects: []
          ret[ancestor_path].projects.push item_doc

    return ret

  _setupProjectsCollectionContextmenu: ->
    self = @

    fields_to_determine_task_projects_collection_and_project_type = 
      [JustdoDeliveryPlanner.task_is_project_field_name]: 1
      [JustdoDeliveryPlanner.task_is_archived_project_field_name]: 1
      projects_collection: 1

    getTaskWithDeliveryPlannerRelatedFields = (task_id) ->
      return APP.collections.Tasks.findOne(task_id, fields_to_determine_task_projects_collection_and_project_type)

    APP.justdo_tasks_context_menu.registerSectionItem "projects", "unset-unknown-projects-collection",
      position: 109
      data:
        icon_type: "feather"
        icon_val: "x-circle"
        label: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) -> 
          i18n_data = 
            label_i18n: "projects_collection_unset_unknown_type_label"
            options_i18n: {}
          return TAPi18n.__ i18n_data.label_i18n, i18n_data.options_i18n, JustdoI18n.default_lang
        label_i18n: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          i18n_data = 
            label_i18n: "projects_collection_unset_unknown_type_label"
            options_i18n: {}
          return i18n_data
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) =>
          self.unsetTaskProjectCollectionType task_id
          return 
      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        task = getTaskWithDeliveryPlannerRelatedFields(task_id)
        is_allowed_by_permissions = APP.justdo_permissions.checkTaskPermissions("task-field-edit.projects_collection.projects_collection_type", task_id)
        is_task_project = self.isTaskObjProject task
        task_projects_collection_type_id = self.getTaskObjProjectsCollectionTypeId(task)
        is_type_not_recognized = not self.getProjectsCollectionTypeById(task_projects_collection_type_id)?
        return is_allowed_by_permissions and (not is_task_project) and task_projects_collection_type_id? and is_type_not_recognized

    position = 110
    for projects_collection_type in @getSupportedProjectsCollectionTypes()
      do (projects_collection_type) =>
        type_id = projects_collection_type.type_id
        dashed_type_id = type_id.replace /_/g, "-"

        APP.justdo_tasks_context_menu.registerSectionItem "projects", "set-unset-as-projects-collection-#{dashed_type_id}",
          position: position
          data:
            label: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) -> 
              i18n_data = 
                label_i18n: projects_collection_type.set_as_i18n
                options_i18n: {}
              task = getTaskWithDeliveryPlannerRelatedFields(task_id)
              task_projects_collection_type_id = self.getTaskObjProjectsCollectionTypeId task
              if task_projects_collection_type_id is type_id
                i18n_data.label_i18n = projects_collection_type.unset_as_i18n

              return TAPi18n.__ i18n_data.label_i18n, i18n_data.options_i18n, JustdoI18n.default_lang
            label_i18n: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
              i18n_data = 
                label_i18n: projects_collection_type.set_as_i18n
                options_i18n: {}
              
              task = getTaskWithDeliveryPlannerRelatedFields(task_id)
              task_projects_collection_type_id = self.getTaskObjProjectsCollectionTypeId task
              if task_projects_collection_type_id is type_id
                i18n_data.label_i18n = projects_collection_type.unset_as_i18n

              return i18n_data
            op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) =>
              task = getTaskWithDeliveryPlannerRelatedFields(task_id)
              if type_id is self.getTaskObjProjectsCollectionTypeId(task)
                self.unsetTaskProjectCollectionType task_id, (err) ->
                  if err?
                    JustdoSnackbar.show 
                      text: err.reason or err
              else
                self.setTaskProjectCollectionType task_id, type_id, (err) ->
                  if err?
                    JustdoSnackbar.show 
                      text: err.reason or err
              return 
            icon_type: "feather"
            icon_val: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
              task = getTaskWithDeliveryPlannerRelatedFields(task_id)
              if self.getTaskObjProjectsCollectionTypeId(task) is type_id
                return projects_collection_type.unset_op_icon.val
              return projects_collection_type.type_icon.val
            icon_class: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
              task = getTaskWithDeliveryPlannerRelatedFields(task_id)
              if self.getTaskObjProjectsCollectionTypeId(task) is type_id
                return projects_collection_type.unset_op_icon.class
              return projects_collection_type.type_icon.class
          listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            task = getTaskWithDeliveryPlannerRelatedFields(task_id)
            is_allowed_by_permissions = APP.justdo_permissions.checkTaskPermissions("task-field-edit.projects_collection.projects_collection_type", task_id)
            is_task_project = self.isTaskObjProject task
            task_projects_collection_type_id = self.getTaskObjProjectsCollectionTypeId(task)
            is_type_not_set = not task_projects_collection_type_id?
            is_type_the_same = task_projects_collection_type_id is type_id
            return is_allowed_by_permissions and (is_type_the_same or (is_type_not_set and not is_task_project))

        position += 1

        APP.justdo_tasks_context_menu.registerSectionItem "projects", "open-close-projects-collection-#{dashed_type_id}",
          position: position
          data:
            label: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
              i18n_data = 
                label_i18n: projects_collection_type.close_i18n
                options_i18n: {}
              task = getTaskWithDeliveryPlannerRelatedFields(task_id)

              if self.isProjectsCollectionClosed task
                i18n_data.label_i18n = projects_collection_type.reopen_i18n

              return TAPi18n.__ i18n_data.label_i18n, i18n_data.options_i18n, JustdoI18n.default_lang 
            label_i18n: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
              i18n_data = 
                label_i18n: projects_collection_type.close_i18n
                options_i18n: {}
              task = getTaskWithDeliveryPlannerRelatedFields(task_id)

              if self.isProjectsCollectionClosed task
                i18n_data.label_i18n = projects_collection_type.reopen_i18n

              return i18n_data
            op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) =>
              task = getTaskWithDeliveryPlannerRelatedFields(task_id)
              if self.isProjectsCollectionClosed task
                self.reopenProjectsCollection task_id
              else
                self.closeProjectsCollection task_id
              return 
            icon_type: "feather"
            icon_val: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
              task = getTaskWithDeliveryPlannerRelatedFields(task_id)
              is_closed = self.isProjectsCollectionClosed task
              if is_closed
                return projects_collection_type.reopen_op_icon.val
              return projects_collection_type.close_op_icon.val
            icon_class: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
              task = getTaskWithDeliveryPlannerRelatedFields(task_id)
              is_closed = self.isProjectsCollectionClosed task
              if is_closed
                return projects_collection_type.reopen_op_icon.class
              return projects_collection_type.close_op_icon.class
          listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            task = getTaskWithDeliveryPlannerRelatedFields(task_id)
            is_allowed_by_permissions = APP.justdo_permissions?.checkTaskPermissions("task-field-edit.projects_collection.is_closed", task_id)
            is_task_projects_collection = self.getTaskObjProjectsCollectionTypeId(task)?
            is_task_project_collection_type_the_same = self.getTaskObjProjectsCollectionTypeId(task) is type_id

            return is_task_projects_collection and is_allowed_by_permissions and is_task_project_collection_type_the_same

        position += 1

        APP.justdo_tasks_context_menu.registerSectionItem "projects", "create-sub-projects-collection-#{dashed_type_id}",
          position: position
          data:
            label: TAPi18n.__ projects_collection_type.add_sub_item_i18n, {}, JustdoI18n.default_lang
            label_i18n: projects_collection_type.add_sub_item_i18n
            op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info, gc) =>
              fields = 
                project_id: JD.activeJustdoId()
                state: "nil"
                projects_collection:
                  projects_collection_type: type_id
                
              gc.addSubItem fields, (err) ->
                if err?
                  JustdoSnackbar.show 
                    text: err.reason or err
                return
            icon_type: "feather"
            icon_val: "corner-down-right"
            icon_class: "create-sub-projects-collection"
          listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
            task = getTaskWithDeliveryPlannerRelatedFields(task_id)
            is_task_projects_collection = self.getTaskObjProjectsCollectionTypeId(task)?
            is_allowed_by_permissions = APP.justdo_permissions?.checkTaskPermissions("grid-structure.add-remove-sort-children", task_id)

            return is_task_projects_collection and is_allowed_by_permissions

        position += 1

    return

  _destroyProjectsCollectionContextmenu: ->
    APP.justdo_tasks_context_menu.unregisterSectionItem "projects", "unset-unknown-projects-collection"
    for projects_collection_type in @getSupportedProjectsCollectionTypes()
      type_id = projects_collection_type.type_id
      dashed_type_id = type_id.replace /_/g, "-"
      APP.justdo_tasks_context_menu.unregisterSectionItem "projects", "set-unset-as-projects-collection-#{dashed_type_id}"
      APP.justdo_tasks_context_menu.unregisterSectionItem "projects", "open-close-projects-collection-#{dashed_type_id}"
      APP.justdo_tasks_context_menu.unregisterSectionItem "projects", "create-sub-projects-collection-#{dashed_type_id}"
    
    return

  _setupProjectsCollectionAddToContextmenu: ->
    self = @

    fields_to_fetch_for_pc_items =
      _id: 1
      title: 1
      seqId: 1
      parents: 1
      projects_collection: 1

    getProjectsCollectionsOfTypeSortedBySeqId = (type_id, filter_state, active_item_id) ->
      active_item = APP.collections.Tasks.findOne(active_item_id, {fields: {parents: 1}})

      current_justdo_id = JD.activeJustdoId()
      if not current_justdo_id?
        return []

      options =
        projects_collection_types: [type_id]
        fields: fields_to_fetch_for_pc_items

      pc_tasks = self.getProjectsCollectionsUnderJustdoCursor(current_justdo_id, options, Meteor.userId()).fetch()

      # Apply filter if provided
      if not _.isEmpty(filter_state)
        filter_regex = new RegExp(JustdoHelpers.escapeRegExp(filter_state), "i")
        pc_tasks = _.filter pc_tasks, (pc_task) ->
          return filter_regex.test(pc_task.title)

      # Exclude items that would cause circular chain
      pc_tasks = self.excludeProjectsCauseCircularChain pc_tasks, active_item_id

      # Sort: items the task already belongs to first, then by seqId descending
      pc_tasks = pc_tasks.sort (pc_task_a, pc_task_b) ->
        is_in_pc_a = pc_task_a._id of (active_item?.parents or {})
        is_in_pc_b = pc_task_b._id of (active_item?.parents or {})
        if is_in_pc_a and not is_in_pc_b
          return -1
        else if not is_in_pc_a and is_in_pc_b
          return 1

        # Sort by seqId descending
        if pc_task_a.seqId < pc_task_b.seqId
          return 1
        else
          return -1

      return pc_tasks

    addNewParentToTaskId = (task_id, new_parent_id, gc, cb) ->
      gc.saveAndExitActiveEditor()

      gc._performLockingOperation (releaseOpsLock, timedout) =>
        usersDiffConfirmationCbWrappedWithGc = (item_id, target_id, diff, confirm, cancel, options) ->
          return ProjectPageDialogs.JustdoTaskMembersDiffDialog.usersDiffConfirmationCb(item_id, target_id, diff, confirm, cancel, _.extend {grid_control: gc}, options)

        gc.addParent task_id, {parent: new_parent_id, order: 0}, (err) ->
          releaseOpsLock()

          cb?(err)

          return
        , usersDiffConfirmationCbWrappedWithGc

        return

      return

    removeParent = (item_path, gc, cb) ->
      gc._performLockingOperation (releaseOpsLock, timedout) =>
        gc._grid_data?.removeParent item_path, (err) =>
          releaseOpsLock()

          if err?
            APP.logger.error "Error: #{err}"

          cb?(err)

          return

        return

      return
    
    for projects_collection_type in @getSupportedProjectsCollectionTypes()
      do (projects_collection_type, position) =>
        type_id = projects_collection_type.type_id
        section_id = "#{JustdoDeliveryPlanner.add_to_projects_collection_section_id_prefix}#{JustdoHelpers.underscoreSepTo "-", type_id}"
        nested_section_id = "#{section_id}-items"

        projects_collection_type_label_i18n = projects_collection_type.type_label_i18n
        projects_collection_type_label_i18n_plural = projects_collection_type.type_label_plural_i18n

        # Register the main section item that opens the nested section
        APP.justdo_tasks_context_menu.registerSectionItem "projects", section_id,
          position: 90 # Before the "Add to Project" section
          data:
            label: ->
              label_i18n = "projects_collection_add_to_projects_collection"
              options_i18n = 
                projects_collection: TAPi18n.__ projects_collection_type_label_i18n, {}, JustdoI18n.default_lang
              return TAPi18n.__ label_i18n, options_i18n, JustdoI18n.default_lang
            label_i18n: ->
              label_i18n = "projects_collection_add_to_projects_collection"
              options_i18n = 
                projects_collection: TAPi18n.__ projects_collection_type_label_i18n
              return {label_i18n, options_i18n}
            is_nested_section: true
            icon_type: "feather"
            icon_val: -> "corner-#{APP.justdo_i18n.getRtlAwareDirection "right"}-down"

          listingCondition: ->
            if not (current_justdo_id = JD.activeJustdoId())?
              return false

            cache_key = "justdo-has-pc-#{type_id}::#{current_justdo_id}"
            if JustdoHelpers.sameTickCacheExists(cache_key)
              return JustdoHelpers.sameTickCacheGet(cache_key)

            options =
              projects_collection_types: [type_id]
              fields:
                _id: 1

            justdo_has_pc = self.getProjectsCollectionsUnderJustdoCursor(current_justdo_id, options, Meteor.userId()).count() > 0

            JustdoHelpers.sameTickCacheSet(cache_key, justdo_has_pc)

            return justdo_has_pc

        # Register the nested section with itemsGenerator
        APP.justdo_tasks_context_menu.registerNestedSection "projects", section_id, nested_section_id,
          position: 100

          data:
            display_item_filter_ui: true
            limit_rendered_items: true

            itemsGenerator: ->
              gc = APP.justdo_tasks_context_menu.getGridControlWithOpenedContextMenu()

              current_section_filter_state = APP.justdo_tasks_context_menu.getSectionFilterState(nested_section_id)

              cache_key = "#{nested_section_id}::#{current_section_filter_state}"
              if JustdoHelpers.sameTickCacheExists(cache_key)
                return JustdoHelpers.sameTickCacheGet(cache_key)

              res = []

              active_item_id = gc.activeItemId()
              pc_docs = getProjectsCollectionsOfTypeSortedBySeqId(type_id, current_section_filter_state, active_item_id)
              # Filter out current task from the list
              filtered_pc_docs = _.filter pc_docs, (pc_doc) -> pc_doc._id isnt active_item_id

              if _.isEmpty(filtered_pc_docs)
                res.push
                  label: ->
                    label_i18n = "projects_collection_no_projects_collection_available"
                    options_i18n = 
                      projects_collection: TAPi18n.__ projects_collection_type_label_i18n_plural, {}, JustdoI18n.default_lang
                    return TAPi18n.__ label_i18n, options_i18n, JustdoI18n.default_lang
                  label_i18n: ->
                    label_i18n = "projects_collection_no_projects_collection_available"
                    options_i18n = 
                      projects_collection: TAPi18n.__ projects_collection_type_label_i18n_plural
                    return {label_i18n, options_i18n}
                  op: -> return
                  icon_type: "none"

              for pc_task_doc, i in pc_docs
                do (pc_task_doc, i) ->
                  if pc_task_doc._id != active_item_id
                    res.push
                      id: pc_task_doc._id

                      label: ->
                        return pc_task_doc.title or ""
                      label_addendum_template: "projects_collection_jump_to_pc"
                      op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info, gc) ->
                        query =
                          _id: task_id
                          "parents.#{pc_task_doc._id}": {$exists: true}

                        options =
                          fields:
                            _id: 1
                            parents: 1

                        if (task_doc = APP.collections.Tasks.findOne(query, options))?
                          performRemoveParent = ->
                            removeParent "/#{pc_task_doc._id}/#{task_id}/", gc, (err) ->
                              if err?
                                console.error err
                              return
                          if _.size(task_doc.parents) > 1
                            performRemoveParent()
                          else
                            JustdoSnackbar.show
                              text: "This is the last parent of the task, do you want to remove the task completely?"
                              showDismissButton: true
                              actionText: "Remove"
                              duration: 10000
                              onActionClick: (snackbar) =>
                                performRemoveParent()
                                snackbar.close()
                                return
                        else
                          addNewParentToTaskId task_id, pc_task_doc._id, gc, (err) ->
                            if err?
                              console.error err
                            return

                        return
                      icon_type: "feather"
                      icon_val: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
                        if not task_id?
                          return

                        query =
                          _id: task_id

                        options =
                          fields:
                            _id: 1
                            parents: 1

                        task_doc = APP.collections.Tasks.findOne(query, options)

                        if pc_task_doc._id of task_doc.parents
                          return "check-square"
                        return "square"

                      close_on_click: false

              JustdoHelpers.sameTickCacheSet(cache_key, res)
              return res

      position += 1

    return

  _destroyProjectsCollectionAddToContextmenu: ->
    for projects_collection_type in @getSupportedProjectsCollectionTypes()
      type_id = projects_collection_type.type_id
      section_id = "#{JustdoDeliveryPlanner.add_to_projects_collection_section_id_prefix}#{JustdoHelpers.underscoreSepTo "-", type_id}"
      APP.justdo_tasks_context_menu.unregisterSectionItem "projects", section_id
      # Note: Nested sections are automatically cleaned up when the parent section item is unregistered

    return

  _registerProjectsCollectionPlugin: ->
    APP.justdo_custom_plugins.installCustomPlugin
      # SETTINGS BEGIN
      #
      # The following properties should be defined by all custom plugins
      custom_plugin_id: JustdoDeliveryPlanner.projects_collection_plugin_id

      custom_plugin_readable_name: TAPi18n.__ JustdoDeliveryPlanner.projects_collection_plugin_name_i18n

      show_in_extensions_list: true
      # / SETTINGS END

      priority: 10050
    
      installer: ->
        return

      destroyer: ->
        return

    return
  
  _unregisterProjectsCollectionPlugin: ->
    APP.justdo_custom_plugins.uninstallCustomPlugin JustdoDeliveryPlanner.projects_collection_plugin_id

    APP.modules.project_page.project_config_ui.unregisterConfigTemplate "extensions", JustdoDeliveryPlanner.projects_collection_plugin_id
    
    return

  _setupProjectsCollectionPlugin: ->
    if not @isProjectsCollectionEnabledGlobally()
      @_registerProjectsCollectionPlugin()

    return

  _setupProjectsCollectionTaskType: ->
    self = @

    closed_project_collection_prefix = "closed_"

    filter_list_order = 2
    tags_properties = 
      unknown_projects_collection_type:
        text: TAPi18n.__ "projects_collection_unknown_type_label", {}, JustdoI18n.default_lang
        text_i18n: "projects_collection_unknown_type_label"
        bg_color: "#f0f0f0"
        is_conditional: true
        filter_list_order: filter_list_order
        customFilterQuery: (filter_state_id, column_state_definitions, context) ->
            return {"projects_collection.projects_collection_type": {$ne: null, $nin: _.pluck self.getSupportedProjectsCollectionTypes(), "type_id"}}
    filter_list_order += 1

    for collection_type_def in self.getSupportedProjectsCollectionTypes()
      do (collection_type_def, filter_list_order) ->
        type_id = collection_type_def.type_id

        tags_properties[type_id] =
          text: TAPi18n.__ collection_type_def.type_label_i18n, {}, JustdoI18n.default_lang
          text_i18n: collection_type_def.type_label_i18n
          filter_list_order: filter_list_order
          bg_color: null
          customFilterQuery: (filter_state_id, column_state_definitions, context) ->
            return {"projects_collection.projects_collection_type": type_id, "projects_collection.is_closed": {$ne: true}}
        
        filter_list_order += 1

        tags_properties["#{closed_project_collection_prefix}#{type_id}"] =
          text: TAPi18n.__ collection_type_def.closed_label_i18n, {}, JustdoI18n.default_lang
          text_i18n: collection_type_def.closed_label_i18n
          filter_list_order: filter_list_order
          bg_color: null
          is_conditional: true
          customFilterQuery: (filter_state_id, column_state_definitions, context) ->
            type_id_without_closed_prefix = type_id.replace closed_project_collection_prefix, ""
            return {"projects_collection.projects_collection_type": type_id_without_closed_prefix, "projects_collection.is_closed": true}
        
        filter_list_order += 1 

    possible_tags = []
    conditional_tags = []
    for tag_id, tag_def of tags_properties
      if tag_def.is_conditional
        conditional_tags.push tag_id
      else
        possible_tags.push tag_id

    APP.justdo_task_type.registerTaskTypesGenerator "default", "projects-collection-type",
      possible_tags: possible_tags
      conditional_tags: conditional_tags

      required_task_fields_to_determine:
        "projects_collection": 1

      generator: (task_obj) ->
        types = []

        if (type_id = self.getTaskObjProjectsCollectionTypeId task_obj)
          if type_id not of tags_properties
            type_id = "unknown_projects_collection_type"

          if self.isProjectsCollectionClosed task_obj
            type_id = "#{closed_project_collection_prefix}#{type_id}"

          types.push type_id

        return types

      propertiesGenerator: (type_id) -> 
        return tags_properties[type_id]

    return

  _destroyProjectsCollectionTaskType: ->
    APP.justdo_task_type.unregisterTaskTypesGenerator "default", "projects-collection-type"

    return

  _setupProjectsCollectionFeatures: ->
    @_setupProjectsCollectionContextmenu()
    @_setupProjectsCollectionAddToContextmenu()
    @_setupProjectsCollectionTaskType()
        
    return

  _destroyProjectsCollectionFeatures: ->
    @_destroyProjectsCollectionContextmenu()
    @_destroyProjectsCollectionAddToContextmenu()
    @_destroyProjectsCollectionTaskType()
        
    return

  _setupProjectsCollectionFeaturesTracker: ->
    if @setup_projects_collection_features_tracker?
      return
  
    @setup_projects_collection_features_tracker = Tracker.autorun =>
      if @isProjectsCollectionEnabled()
        Tracker.nonreactive =>
          @_setupProjectsCollectionFeatures()
          return
      else
        Tracker.nonreactive =>
          @_destroyProjectsCollectionFeatures()
          return
      return

    return
  
  getProjectsCollectionOnGridClickHandler: (event_item) ->
    projects_collection_type_id = @getTaskObjProjectsCollectionTypeId(event_item)
    projects_collection_type_def = @getProjectsCollectionTypeById(projects_collection_type_id)

    return projects_collection_type_def?.onGridClick or JustdoDeliveryPlanner.defaultOnGridProjectsCollectionClick
  
  getProjectOnGridClickHandler: (event_item, event_path) ->
    event_parent_item_id = GridData.helpers.getPathParentId(event_path)
    event_parent_item = APP.collections.Tasks.findOne(event_parent_item_id, {fields: {projects_collection: 1}})
    
    parent_projects_collection_type_id = @getTaskObjProjectsCollectionTypeId(event_parent_item)
    parent_projects_collection_type_def = @getProjectsCollectionTypeById(parent_projects_collection_type_id)

    return parent_projects_collection_type_def?.onGridProjectClick or JustdoDeliveryPlanner.defaultOnGridProjectClick
