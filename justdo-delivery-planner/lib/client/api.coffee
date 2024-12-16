_.extend JustdoDeliveryPlanner.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerTabSwitcherSection() # Moved out of setupCustomFeatureMaintainer once Projects became a builtin feature

    @setupCustomFeatureMaintainer()

    @_setupCustomFeatures()

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

  _setupCustomFeatures: ->
    if not @isProjectsCollectionEnabled()
      return

    @_setupTaskType()
    @_setupContextmenu()
    @_registerTabView()

    @features_tracker = Tracker.autorun =>
      if (gcm = APP.modules.project_page.grid_control_mux.get())?
        @_installTabsOnGcm gcm 
      return

    return

  _setupTaskType: ->
    tags_properties =
      "is_projects_collection":
        text: TAPi18n.__ JustdoProjectsCollection.projects_collection_term_i18n, {}, JustdoI18n.default_lang
        text_i18n: JustdoProjectsCollection.projects_collection_term_i18n

        filter_list_order: 15

        customFilterQuery: (filter_state_id, column_state_definitions, context) ->
          return {"projects_collection.is_projects_collection": true}

    APP.justdo_task_type.registerTaskTypesGenerator "default", "is-projects-collection",
      possible_tags: ["is_projects_collection"]

      required_task_fields_to_determine:
        "projects_collection.is_projects_collection": 1

      generator: (task_obj) ->
        tags = []

        if task_obj?.projects_collection?.is_projects_collection is true
          tags.push "is_projects_collection"

        return tags

      propertiesGenerator: (tag) -> tags_properties[tag]

    return
  
  _setupContextmenu: ->
    self = @

    if @app_type isnt "web-app"
      return
    
    APP.justdo_tasks_context_menu.registerMainSection JustdoProjectsCollection.project_custom_feature_id,
      position: 1000
      data:
        label: TAPi18n.__ JustdoProjectsCollection.projects_collection_term_i18n, {}, JustdoI18n.default_lang
        label_i18n: JustdoProjectsCollection.projects_collection_term_i18n

    APP.justdo_tasks_context_menu.registerSectionItem JustdoProjectsCollection.project_custom_feature_id, "set-unset-as-projects-collection",
      position: 100
      data:
        label: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) -> 
          i18n_data = 
            label_i18n: "projects_collection_set_as_projects_collection"
            options_i18n: 
              collection_name: TAPi18n.__ "projects_collection_term", {}, JustdoI18n.default_lang

          if task_id? and self.isTaskProjectsCollection task_id
            i18n_data.label_i18n = "projects_collection_unset_as_projects_collection"

          return TAPi18n.__ i18n_data.label_i18n, i18n_data.options_i18n, JustdoI18n.default_lang
        label_i18n: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          i18n_data = 
            label_i18n: "projects_collection_set_as_projects_collection"
            options_i18n: 
              collection_name: TAPi18n.__ "projects_collection_term"

          if task_id? and self.isTaskProjectsCollection task_id
            i18n_data.label_i18n = "projects_collection_unset_as_projects_collection"

          return i18n_data
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) =>
          self.toggleTaskAsProjectsCollection task_id
          return 
        icon_type: "feather"
        icon_val: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          if task_id? and self.isTaskProjectsCollection task_id
            return "jd-folder-unset"
          return "folder"
      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        return APP.justdo_permissions?.checkTaskPermissions("task-field-edit.projects_collection.is_projects_collection", task_id)

    APP.justdo_tasks_context_menu.registerSectionItem JustdoProjectsCollection.project_custom_feature_id, "open-close-projects-collection",
      position: 200
      data:
        label: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          i18n_data = 
            label_i18n: "projects_collection_close_projects_collection"
            options_i18n: 
              collection_name: TAPi18n.__ "projects_collection_term", {}, JustdoI18n.default_lang

          if task_id? and self.isProjectsCollectionClosed task_id
            i18n_data.label_i18n = "projects_collection_reopen_projects_collection"

          return TAPi18n.__ i18n_data.label_i18n, i18n_data.options_i18n, JustdoI18n.default_lang 
        label_i18n: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          i18n_data = 
            label_i18n: "projects_collection_close_projects_collection"
            options_i18n: 
              collection_name: TAPi18n.__ "projects_collection_term"

          if task_id? and self.isProjectsCollectionClosed task_id
            i18n_data.label_i18n = "projects_collection_reopen_projects_collection"

          return i18n_data
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) =>
          self.toggleProjectsCollectionClosedState task_id
          return 
        icon_type: "feather"
        icon_val: "folder"
      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        is_task_projects_collection = self.isTaskProjectsCollection task_id
        return is_task_projects_collection and APP.justdo_permissions?.checkTaskPermissions("task-field-edit.projects_collection.is_closed", task_id)

    return
  
  _registerTabView: ->
    self = @
    tab_switcher_manager = APP.modules.project_page.tab_switcher_manager

    tab_switcher_manager.registerSectionItem "main", "projects_collection",
      position: 500
      data:
        label: TAPi18n.__ JustdoProjectsCollection.projects_collection_term_i18n, {}, JustdoI18n.default_lang
        label_i18n: JustdoProjectsCollection.projects_collection_term_i18n
        tab_id: "justdo_projects_collection"
        icon_type: "feather"
        icon_val: "book"

        tab_section_state:
          global:
            tracked_field: "projects_collection.is_projects_collection"

    return

  _installTabsOnGcm: (gcm) ->
    if gcm.destroyed == true
      # Nothing to do
      return
    
    if gcm._projects_collection_tab_installed
      return
    
    self = @
    gcOpsGen = APP.modules.project_page.generateGridControlOptionsForSections
    
    gcm.addTab "justdo_projects_collection",
      grid_control_options: gcOpsGen [
        {
          id: "projects-collection"
          section_manager: "QuerySection"
          options:
            permitted_depth: 1
            section_item_title: TAPi18n.__ JustdoProjectsCollection.projects_collection_term_i18n
            expanded_on_init: true
            show_if_empty: false
          section_manager_options:
            query: ->
              query = 
                project_id: JD.activeJustdoId()
                "projects_collection.is_projects_collection": true
              
              return self.tasks_collection.find(query, {sort: {seqId: 1}}).fetch()
        }
      ]
      removable: true
      activate_on_init: false
      tabTitleGenerator: -> TAPi18n.__ JustdoProjectsCollection.projects_collection_term_i18n
    
    gcm._projects_collection_tab_installed = true

    return

