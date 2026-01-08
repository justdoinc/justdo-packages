_.extend JustdoPwa.prototype,
  _immediateInit: ->
    @is_mobile_layout_rv = new ReactiveVar false
    @_setupIsMobileLayoutTracker()

    @active_tab_rv = new ReactiveVar "main"

    @_setupGlobalTemplateHelpers()
    @_setupTaskPaneStateTracker()
    @_setupGridControlFrozenColumnsModeTracker()
    @_setupGridControlPreActivateRowHandler()
    @_setupProjectPaneHeightTracker()

    return

  _deferredInit: ->
    if @destroyed
      return

    @_resetActiveTabUponExitingMobileLayout()

    return

  _setupIsMobileLayoutTracker: ->
    APP.executeAfterAppLibCode =>
      @is_mobile_layout_tracker = Tracker.autorun =>
        # The reason we have `is_mobile_layout_rv` instead of returning `@getBrowserDimension().width < JustdoPwa.mobile_breakpoint`
        # directly in `isMobileLayout` is to avoid unnecessary re-evaluations of the tracker depending on it,
        # since `@getBrowserDimension()` triggers re-computation on every pixel change in the window size.
        @is_mobile_layout_rv.set @getBrowserDimension().width < JustdoPwa.mobile_breakpoint
        return

      @onDestroy =>
        @is_mobile_layout_tracker?.stop()
        @is_mobile_layout_tracker = null
        return

      return

    return

  _resetActiveTabUponExitingMobileLayout: ->
    # This tracker is used to reset the active tab to "main" when the screen changes to desktop layout,
    # so that the `onDeactivate` callback of the active tab is called to perform any necessary cleanup
    # e.g. unsubscribe from publications.

    @_reset_active_tab_upon_exiting_mobile_layout_tracker = Tracker.autorun =>
      if not @isMobileLayout()
        @setActiveTab("main")

      return

    @onDestroy =>
      @_reset_active_tab_upon_exiting_mobile_layout_tracker?.stop()
      @_reset_active_tab_upon_exiting_mobile_layout_tracker = null
      return
    
    return
  
  _setupGlobalTemplateHelpers: ->
    Template.registerHelper "hideInMobileLayout", (display_mode) ->
      if not display_mode?
        display_mode = "block"
      
      return "d-none d-md-#{display_mode}"
      
    return

  _setupTaskPaneStateTracker: ->
    # This tracker is used to hide the task pane when the screen changes to mobile layout,
    # and restore to the original task pane state when the screen changes to desktop layout.

    APP.executeAfterAppLibCode =>
      is_mobile_layout = false
      is_task_pane_expanded_before_mobile_layout = false

      @task_pane_state_tracker = Tracker.autorun =>
        project_page_preferences = APP.modules.project_page.preferences.get()

        prev_is_mobile_layout = is_mobile_layout
        is_mobile_layout = @isMobileLayout()

        is_entering_mobile_layout = is_mobile_layout and (not prev_is_mobile_layout)
        is_exiting_mobile_layout = (not is_mobile_layout) and prev_is_mobile_layout

        if is_entering_mobile_layout
          # When a user first loads the app, project_page_preferences.toolbar_open does not exist yet.
          # In that case, it's regarded as true by WireframeManager (search for `toolbar_open` in 015-project-page-wireframe-manager.coffee)
          if (project_page_preferences.toolbar_open is true) or (not project_page_preferences.toolbar_open?)
            is_task_pane_expanded_before_mobile_layout = true
            APP.modules.project_page.updatePreferences({toolbar_open: false})
          else
            is_task_pane_expanded_before_mobile_layout = false
        else if is_exiting_mobile_layout
          if is_task_pane_expanded_before_mobile_layout
            APP.modules.project_page.updatePreferences({toolbar_open: true})

          is_task_pane_expanded_before_mobile_layout = null
        
        return

      @onDestroy =>
        @task_pane_state_tracker?.stop()
        @task_pane_state_tracker = null
        return
      
      return

    return

  _setupGridControlFrozenColumnsModeTracker: ->
    # This checks whether mobile layout is active and triggers a re-evaluation
    # of frozen columns mode on grid controls.
    # This ensures frozen columns are disabled in mobile view and
    # re-enabled (if applicable) in desktop view.
    
    APP.on "grid-control-created", (grid_control) =>
      # We wait for the "init" event to ensure grid_control._grid is available.
      grid_control.on "init", =>
        if grid_control.pwa_frozen_columns_mode_tracker?
          return

        grid_control.pwa_frozen_columns_mode_tracker = Tracker.autorun =>
          if @isMobileLayout()
            grid_control.disableFrozenColumnsMode()
            grid_control.exitFrozenColumnsMode()
          else
            grid_control.enableFrozenColumnsMode()
            grid_control.reevaluateFrozenColumnsMode()

          return

        grid_control.onDestroy =>
          grid_control.pwa_frozen_columns_mode_tracker.stop()
          grid_control.pwa_frozen_columns_mode_tracker = null
          return

        return

      return

    return

  _setupGridControlPreActivateRowHandler: ->
    # This hook is responsible to set the active tab to "main" when a row is activated in the main grid under mobile layout.
    APP.on "grid-control-created", (grid_control) =>
      if grid_control.getDomain() isnt "project-page-main-grid"
        return
      
      grid_control.on "pre-activate-row", =>
        if @isMobileLayout()
          @setActiveTab("main")
          return

        return

      return
    return

  _setupProjectPaneHeightTracker: ->
    # This tracker is responsible for setting the collapsed project pane height to 0 under mobile layout
    # to alllow accurate layout rendering.
    JustdoHelpers.hooks_barriers.runCbAfterBarriers "post-justdo-project-pane-init", =>
      @project_pane_height_tracker = Tracker.autorun =>
        if @isMobileLayout()
          APP.justdo_project_pane.setCollapsedHeight 0
        else
          APP.justdo_project_pane.setCollapsedHeight JustdoProjectPane.collapsed_height
        return

      @onDestroy =>
        @project_pane_height_tracker?.stop()
        @project_pane_height_tracker = null
        return

      return

    return

  getBrowserDimension: ->
    return APP.modules.main.window_dim.get()

  isMobileLayout: ->
    return @is_mobile_layout_rv.get()
  
  getTabDefinition: (tab_id) ->
    return _.find JustdoPwa.default_mobile_tabs, (tab) -> tab._id is tab_id

  getActiveTab: ->
    return @active_tab_rv.get()

  getActiveTabDefinition: ->
    return @getTabDefinition(@getActiveTab())

  setActiveTab: (new_tab_id) ->
    cur_tab_id = Tracker.nonreactive => @getActiveTab()
    cur_tab_definition = @getTabDefinition(cur_tab_id)
    cur_tab_definition?.onDeactivate?()

    @active_tab_rv.set(new_tab_id)

    new_tab_definition = @getTabDefinition(new_tab_id)
    new_tab_definition?.onActivate?()

    return
