_.extend JustdoPwa.prototype,
  _immediateInit: ->
    @active_tab_rv = new ReactiveVar "main"

    @_setupGlobalTemplateHelpers()
    @_setupTaskPaneStateTracker()
    @_setupGridControlFrozenColumnsModeTracker()

    return

  _deferredInit: ->
    if @destroyed
      return

    @_resetActiveTabUponExitingMobileLayout()

    return

  _resetActiveTabUponExitingMobileLayout: ->
    # This tracker is used to reset the active tab to "main" when the screen changes to desktop layout,
    # so that the `onDeactivate` callback of the active tab is called to perform any necessary cleanup
    # e.g. unsubscribe from publications.
    APP.executeAfterAppLibCode =>
      prev_is_mobile_layout = @isMobileLayout()
      @_reset_active_tab_upon_exiting_mobile_layout_tracker = Tracker.autorun =>
        if prev_is_mobile_layout and not @isMobileLayout()
          @setActiveTab("main")

        prev_is_mobile_layout = @isMobileLayout()
        return

      @onDestroy =>
        @_reset_active_tab_upon_exiting_mobile_layout_tracker?.stop()
        @_reset_active_tab_upon_exiting_mobile_layout_tracker = null
        return
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
          if project_page_preferences.toolbar_open
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
    # This tracker listens for window resize events and triggers a re-evaluation
    # of frozen columns mode on all registered grid controls when the mobile layout
    # state changes. This ensures frozen columns are disabled in mobile view and
    # re-enabled (if applicable) in desktop view.
    
    APP.executeAfterAppLibCode =>
      @grid_control_frozen_columns_mode_tracker = Tracker.autorun =>
        is_mobile_layout = @isMobileLayout()

        for grid_control in GridControl.getAllRegisteredGridControls()
          if is_mobile_layout
            grid_control.disableFrozenColumnsMode()
            grid_control.exitFrozenColumnsMode()
          else
            grid_control.enableFrozenColumnsMode()
            grid_control.reevaluateFrozenColumnsMode()

        return

      @onDestroy =>
        @grid_control_frozen_columns_mode_tracker?.stop()
        @grid_control_frozen_columns_mode_tracker = null
        return

      return

    return

  getBrowserDimention: ->
    return APP.modules.main.window_dim.get()

  isMobileLayout: ->
    return @getBrowserDimention().width < JustdoPwa.mobile_breakpoint
  
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
