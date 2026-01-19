_.extend JustdoPwa.prototype,
  _immediateInit: ->
    @is_mobile_layout_rv = new ReactiveVar false
    @_setupIsMobileLayoutTracker()

    @mobile_tabs = {}
    @mobile_tabs_dep = new Tracker.Dependency()
    @_setupDefaultMobileTabs()

    @active_mobile_tab_rv = new ReactiveVar JustdoPwa.main_mobile_tab_id

    @_setupGlobalTemplateHelpers()
    @_setupMeteorStatusShowDelayTracker()
    @_setupTaskPaneStateTracker()
    @_setupGridControlFrozenColumnsModeTracker()
    @_setupGridControlPreActivateRowHandler()
    @_setupGridControlClickToShowHeaderContextMenuHandler()
    @_setupProjectPaneHeightTracker()
    @_setupDynamicHead()

    return

  _deferredInit: ->
    if @destroyed
      return

    @_resetActiveMobileTabUponExitingMobileLayout()

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

  _resetActiveMobileTabUponExitingMobileLayout: ->
    # This tracker is used to reset the active tab to JustdoPwa.main_mobile_tab_id when the screen changes to desktop layout,
    # so that the `onDeactivate` callback of the active tab is called to perform any necessary cleanup
    # e.g. unsubscribe from publications.

    @_reset_active_tab_upon_exiting_mobile_layout_tracker = Tracker.autorun =>
      if not @isMobileLayout()
        @setActiveMobileTab(JustdoPwa.main_mobile_tab_id)

      return

    @onDestroy =>
      @_reset_active_tab_upon_exiting_mobile_layout_tracker?.stop()
      @_reset_active_tab_upon_exiting_mobile_layout_tracker = null
      return
    
    return
  
  _setupGlobalTemplateHelpers: ->
    self = @

    Template.registerHelper "isMobileLayout", ->
      return self.isMobileLayout()

    Template.registerHelper "hideInMobileLayout", (display_mode) ->
      if not display_mode?
        display_mode = "block"
      
      return "d-none d-md-#{display_mode}"
      
    return

  _setupMeteorStatusShowDelayTracker: ->
    original_show_delay = Status.getShowDelay()
    @meteor_status_show_delay_tracker = Tracker.autorun =>
      if @isMobileLayout()
        Status.setShowDelay(JustdoPwa.meteor_status_show_delay)
      else
        Status.setShowDelay(original_show_delay)
        
      return
    
    @onDestroy =>
      @meteor_status_show_delay_tracker?.stop()
      @meteor_status_show_delay_tracker = null
      return
    
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
    # This hook is responsible to set the active tab to JustdoPwa.main_mobile_tab_id when a row is activated in the main grid under mobile layout.
    APP.on "grid-control-created", (grid_control) =>
      if grid_control.getDomain() isnt "project-page-main-grid"
        return
      
      grid_control.on "pre-activate-row", =>
        if @isMobileLayout()
          @setActiveMobileTab(JustdoPwa.main_mobile_tab_id)
          return

        return

      return
    return

  _setupGridControlClickToShowHeaderContextMenuHandler: ->
    APP.on "grid-control-created", (grid_control) =>
      column_header_selector = grid_control.getColumnsContextMenuTargetSelector()
      slick_grid_jquery_event =
        args: ["click", column_header_selector]
        handler: (e) =>
          if @isMobileLayout()
            # Create a synthetic `contextmenu` event based on the original `click` event,
            # preserving all coordinates and properties.
            contextMenuEvent = $.Event e,
              type: "contextmenu"
            $(e.currentTarget).trigger(contextMenuEvent)
          return

      grid_control.installCustomJqueryEvent(slick_grid_jquery_event)

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

  _setupDynamicHead: ->
    getMetaViewportContent = ->
      return $("meta[name='viewport']").attr("content")

    original_meta_viewport_content = getMetaViewportContent()
    
    @_dynamic_head_tracker = Tracker.autorun =>
      if @isMobileLayout()
        meta_viewport_content_with_zoom_restriction = original_meta_viewport_content + ", maximum-scale=1.0, user-scalable=no"
        $("meta[name='viewport']").attr("content", meta_viewport_content_with_zoom_restriction)
      else
        $("meta[name='viewport']").attr("content", original_meta_viewport_content)
        return
    
    @onDestroy =>
      @_dynamic_head_tracker?.stop()
      @_dynamic_head_tracker = null
      return
    
    return

  getBrowserDimension: ->
    return APP.modules.main.window_dim.get()

  isMobileLayout: ->
    return @is_mobile_layout_rv.get()
  
  _setupDefaultMobileTabs: ->
    for tab_id, tab_definition of JustdoPwa.default_mobile_tabs
      @registerMobileTab tab_id, tab_definition
      
    return

  _registerMobileTabSchema: new SimpleSchema
    label:
      type: String
    order:
      type: Number
    icon:
      # icon_template will take precedence over icon
      type: String
      optional: true
    icon_template: 
      type: String
      optional: true
    icon_template_data:
      type: Object
      blackbox: true
      optional: true
    tab_template:
      type: String
      optional: true
    tab_template_data:
      type: Object
      blackbox: true
      optional: true
    listingCondition: 
      type: Function
      optional: true
    onActivate:
      type: Function
      optional: true
    onDeactivate:
      type: Function
      optional: true
  registerMobileTab: (tab_id, options) ->
    check tab_id, String
    if @getMobileTab(tab_id)?
      throw @_error "invalid-argument", "Mobile tab #{tab_id} already registered"

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerMobileTabSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    @mobile_tabs[tab_id] = options
    @mobile_tabs_dep.changed()

    return

  unregisterMobileTab: (tab_id) ->
    @requireMobileTab tab_id

    @mobile_tabs = _.without @mobile_tabs, tab_id
    @mobile_tabs_dep.changed()

    return

  getMobileTab: (tab_id) ->
    @mobile_tabs_dep.depend()
    
    if (tab_def = @mobile_tabs[tab_id])?
      cloned_tab_def = _.extend {}, tab_def,
        _id: tab_id

      return cloned_tab_def

    return

  requireMobileTab: (tab_id) ->
    if not (tab = @getMobileTab(tab_id))?
      throw @_error "invalid-argument", "Mobile tab #{tab_id} not registered"

    return tab

  getMobileTabs: ->
    @mobile_tabs_dep.depend()
    
    mobile_tabs = []
    for tab_id, tab_definition of @mobile_tabs
      mobile_tabs.push _.extend {}, tab_definition,
        _id: tab_id

    sorted_mobile_tabs = _.sortBy mobile_tabs, (tab) -> tab.order
    return sorted_mobile_tabs

  getActiveMobileTabId: ->
    return @active_mobile_tab_rv.get()

  getActiveMobileTab: ->
    return @getMobileTab(@getActiveMobileTabId())

  setActiveMobileTab: (new_tab_id) ->
    cur_tab_definition = Tracker.nonreactive => @getActiveMobileTab()
    cur_tab_definition?.onDeactivate?()

    @active_mobile_tab_rv.set(new_tab_id)

    new_tab_definition = @getMobileTab(new_tab_id)
    new_tab_definition?.onActivate?()

    return
