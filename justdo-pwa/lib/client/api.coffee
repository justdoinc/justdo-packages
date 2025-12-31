_.extend JustdoPwa.prototype,
  _immediateInit: ->
    @_setupGlobalTemplateHelpers()
    @_setupTaskPaneStateTracker()
    @_setupGridControlFrozenColumnsModeHandler()

    return

  _deferredInit: ->
    if @destroyed
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
        @task_pane_state_tracker.stop()
        return
      
      return

    return

  _setupGridControlFrozenColumnsModeHandler: ->
    # This tracker listens for window resize events and triggers a re-evaluation
    # of frozen columns mode on all registered grid controls when the mobile layout
    # state changes. This ensures frozen columns are disabled in mobile view and
    # re-enabled (if applicable) in desktop view.
    
    self = @
    resizeHandler = ->
      is_mobile_layout = self.isMobileLayout()

      for grid_control in GridControl.getAllRegisteredGridControls()
        if is_mobile_layout
          grid_control.disableFrozenColumnsMode()
          grid_control.exitFrozenColumnsMode()
        else
          grid_control.enableFrozenColumnsMode()
          grid_control.reevaluateFrozenColumnsMode()

      return

    $(window).on "resize", resizeHandler

    @onDestroy =>
      $(window).off "resize", resizeHandler
      return

    return

  getBrowserDimention: ->
    return APP.modules.main.window_dim.get()

  isMobileLayout: ->
    return @getBrowserDimention().width < JustdoPwa.mobile_breakpoint