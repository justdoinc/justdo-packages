curProj = -> APP.modules.project_page.curProj()

_.extend CustomJustdoSaveDefaultView.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  setupCustomFeatureMaintainer: ->
    active_tab_comp = null

    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage CustomJustdoSaveDefaultView.project_custom_feature_id,
        installer: =>
          active_tab_comp = Tracker.autorun =>
            if not (gcm = APP.modules.project_page.getGridControlMux())?
              @logger.warn "No grid control mux found"

              return

            if (active_tab = gcm.getActiveTab())?
              stored_grid_views = Tracker.nonreactive => @getActiveProjectStoredSavedGridViews()
              default_grid_views = Tracker.nonreactive => @getDefaultViewsForActiveProject()

              if active_tab.tab_id of stored_grid_views
                # User edited the tab, leave it alone
                return

              if active_tab.tab_id of default_grid_views
                # We got a default, set it

                active_tab.grid_control.setView(default_grid_views[active_tab.tab_id])

            return

          return

        destroyer: =>
          active_tab_comp.stop()
          active_tab_comp = null

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  _viewComponentSchema: new SimpleSchema
    field:
      type: String
    width:
      type: Number
    filter:
      type: "skip-type-check"

      optional: true

      blackbox: true
  getDefaultViewsForActiveProject: ->
    if not (views_for_active_project_json = curProj().getProjectConfigurationSetting(CustomJustdoSaveDefaultView.project_conf_key))
      return {}

    views_for_active_project = EJSON.parse(views_for_active_project_json)

    if not _.isObject views_for_active_project
      return {}

    # Validate to avoid XSS surprises.
    for view_id, view_def of views_for_active_project
      if not _.isArray view_def
        return {}

      # XXX Need to fix this one, I got issues with the filters schema - might be an XSS vulnerability
      #
      # view_def = _.map view_def, (view_component) =>
      #   {cleaned_val} =
      #     JustdoHelpers.simpleSchemaCleanAndValidate(
      #       @_viewComponentSchema,
      #       view_component,
      #       {self: @, throw_on_error: true}
      #     )
      #   return cleaned_val

      views_for_active_project[view_id] = view_def

    return views_for_active_project

  saveCurrentViewAsDefaultViewForActiveProject: ->
    current_default_views = @getDefaultViewsForActiveProject()

    if not (gcm = APP.modules.project_page.getGridControlMux())?
      @logger.warn "No grid control mux found"

      return

    active_tab = gcm.getActiveTab()

    current_views = active_tab.grid_control.getView()

    new_default_views = _.extend {}, current_default_views, {"#{active_tab.tab_id}": current_views}

    new_default_views_json = EJSON.stringify(new_default_views)

    APP.modules.project_page.curProj().configureProject({"#{CustomJustdoSaveDefaultView.project_conf_key}": new_default_views_json})

    return

  getActiveProjectStoredSavedGridViews: ->
    if not (project_id = APP.modules.project_page?.project?.get()?.id)?
      @logger.warn "Couldn't find project id"
      return

    return APP.modules.project_page.loadPreferences()?.saved_grid_views?[project_id] or {}

  resetUserViews: ->
    if not (project_id = APP.modules.project_page?.project?.get()?.id)?
      @logger.warn "Couldn't find project id"
      return

    existing_preferences = APP.modules.project_page.preferences.get()

    if not existing_preferences?.saved_grid_views?[project_id]?
      # Nothing to do
      return

    delete existing_preferences.saved_grid_views[project_id]

    APP.modules.project_page.updatePreferences(existing_preferences)

    default_views_for_active_project = @getDefaultViewsForActiveProject()

    if not (gcm = APP.modules.project_page.getGridControlMux())?
      return

    # Reset views for loaded tabs
    for tab_id, tab_def of gcm.getAllTabs()
      if tab_def.state == "ready"
        if tab_id of default_views_for_active_project
          tab_def.grid_control.setView(default_views_for_active_project[tab_id])

    return
