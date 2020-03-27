_.extend JustdoDeliveryPlanner.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @registerTaskPaneSection()
    @setupCustomFeatureMaintainer()

    return

  setupCustomFeatureMaintainer: ->
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

    gridControlMuxCreatedCb = null
    removeGridControlMuxCreatedListener = ->
      if gridControlMuxCreatedCb?
        APP.modules.project_page.removeListener "grid-control-mux-created", gridControlMuxCreatedCb

        gridControlMuxCreatedCb = null

        return

    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoDeliveryPlanner.project_custom_feature_id,

      installer: =>
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
        APP.modules.project_page.on "grid-control-mux-created", gridControlMuxCreatedCb = (gcm) ->
          installTabsOnGcm(gcm)

          return

        if (gcm = APP.modules.project_page.grid_control_mux.get())?
          installTabsOnGcm(gcm)

        @registerTabSwitcherSection()

        return

      destroyer: =>
        removeGridControlMuxCreatedListener()

        @unregisterTabSwitcherSection()

        return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  registerTabSwitcherSection: ->
    self = @

    isInstalledOnCurrentProject = ->
      cur_project = APP.modules.project_page.curProj()

      if not cur_project?
        return

      return cur_project.isCustomFeatureEnabled(JustdoDeliveryPlanner.project_custom_feature_id)

    getAllJustdoActiveProjectsSortedByProjectName = ->
      return APP.justdo_delivery_planner.getKnownProjects(JD.activeJustdo({_id: 1})._id, {active_only: true, sort_by: {title: 1}}, Meteor.userId())

    APP.modules.project_page.tab_switcher_manager.registerSectionItem "main", "projects",
      position: 300
      data:
        label: "Projects"
        tab_id: "jdp-all-projects"

        icon_type: "feather"
        icon_val: "briefcase"
      listingCondition: isInstalledOnCurrentProject
    APP.modules.project_page.tab_switcher_manager.registerSection "projects",
      position: 350
      data:
        label: "Projects"

      listingCondition: ->
        if isInstalledOnCurrentProject() and getAllJustdoActiveProjectsSortedByProjectName().length > 0
          return true

    if self.tab_switcher_items_builder_comp?
      self.tab_switcher_items_builder_comp.stop()

    self.tab_switcher_items_builder_comp = Tracker.autorun ->
      APP.modules.project_page.tab_switcher_manager.resetSectionItems("projects")
      
      for project_task_doc, i in getAllJustdoActiveProjectsSortedByProjectName()
        APP.modules.project_page.tab_switcher_manager.registerSectionItem "projects", project_task_doc._id,
          position: i
          data:
            label: project_task_doc.title
            tab_id: "sub-tree"

            icon_type: "feather"
            icon_val: "briefcase"

            tab_sections_state:
              global:
                "root-item": project_task_doc._id

      return

    return

  unregisterTabSwitcherSection: ->
    APP.modules.project_page.tab_switcher_manager.unregisterSectionItem "main", "projects"

    APP.modules.project_page.tab_switcher_manager.unregisterSection "projects"

    @tab_switcher_items_builder_comp?.stop()
    @tab_switcher_items_builder_comp = null

    return
