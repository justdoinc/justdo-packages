_.extend JustdoDeliveryPlanner.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerTabSwitcherSection() # Moved out of setupCustomFeatureMaintainer once Projects became a builtin feature

    @setupCustomFeatureMaintainer()

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
            op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) =>
              fields = 
                project_id: JD.activeJustdoId()
                state: "nil"
                projects_collection:
                  projects_collection_type: type_id
                
              APP.modules.project_page.gridControl().addSubItem fields, (err) ->
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
