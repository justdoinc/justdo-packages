# shortcut
newComputedReactiveVar = JustdoHelpers.newComputedReactiveVar

_.extend GridControlMux.prototype,
  setupComputedReactiveVars: ->
    # Setup computed reactive variables (CRV)
    # any CRV should be stopped in @destroy

    getActiveTabOrNull = =>
      # Returns the active tab, or null, if there's no active tab
      #
      # A reactive resource, invalidates on every
      # @_grid_controls_tabs change, returns active
      # tab, used by the CRVs comps below to isolate
      # reactivity on specific property of the
      # active tab
      @_grid_controls_tabs_dependency.depend()

      if (tab = @getActiveTabNonReactive())?
        return tab

      return null

    isIdentical = (a, b) -> a is b

    #
    # @_current_active_tab
    #
    @_current_active_tab_crv =
      newComputedReactiveVar "current_active_tab", getActiveTabOrNull,
        # options
        reactiveVarEqualsFunc: isIdentical

    #
    # @_current_grid_control_crv
    #
    @_current_grid_control_crv = newComputedReactiveVar "current_grid_control", =>
      if (active_tab = getActiveTabOrNull())?
        return active_tab.grid_control

      return null
    , # options
      reactiveVarEqualsFunc: isIdentical

    #
    # @_current_grid_control_if_ready_crv
    #
    @_current_grid_control_if_ready_crv = newComputedReactiveVar "current_grid_control_if_ready", =>
      # Returns the current grid control only if tab
      # is ready
      if (active_tab = getActiveTabOrNull())?
        if active_tab.state == "ready"
          return active_tab.grid_control

      return null
    , # options
      reactiveVarEqualsFunc: isIdentical

    #
    # @_current_path_crv
    #
    @_current_path_crv = newComputedReactiveVar "current_gcm_path", =>
      # Read @getPath below about the value returned by this crv

      # As long as setPath is onGoing, return the
      # @_pre_setPath_path
      @_ongoing_setPath_dependency.depend()
      if @_ongoing_setPath
        @logger.debug "@_current_path_crv: @_ongoing_setPath is on, returning pre_setPath_path"

        return @_pre_setPath_path

      if not (active_tab = @getActiveTab())?
        @logger.debug "@_current_path_crv: no active tab"

        current_tab_id = null
        current_path = null
      else
        current_tab_id = active_tab.tab_id

        # As long as the grid control isn't ready
        # we regard it as having no path
        if not (active_grid_control = @getActiveGridControl(true))?
          @logger.debug "@_current_path_crv: no ready grid"
          current_path = null
        else
          @logger.debug "@_current_path_crv: ready grid"
          current_path = active_grid_control.getCurrentPath()

      return [current_tab_id, current_path]
    , # options
      reactiveVarEqualsFunc: JustdoHelpers.jsonComp

  destroyComputedReactiveVars: ->
    @_current_active_tab_crv.stop()
    @_current_grid_control_crv.stop()
    @_current_grid_control_if_ready_crv.stop()
    @_current_path_crv.stop()

  isItemsSubscriptionReady: ->
    # Reactive resource

    @items_subscription.ready()

  subscriptionReadyProcedures: ->
    @logger.debug "Subscription ready"

    gct_changed = false

    for tab_id, tab of @getAllTabs()
      if tab.state == "loading-waiting-subscription"
        gct_changed = true
        tab.state = "ready"

        @emit "tab-ready", tab

    if gct_changed
      @_grid_controls_tabs_dependency.changed()

    return

  getAllTabs: ->
    # Returns @_grid_controls_tabs
    #
    # Reactive resource
    #
    # IMPORTANT:
    # For full details about the specific properties
    # of the returned object that will trigger reactivity
    # upon change, please refer to client/init.coffee
    @_grid_controls_tabs_dependency.depend()

    return @_grid_controls_tabs

  getAllTabsNonReactive: -> @_grid_controls_tabs

  getTabNonReactive: (tab_id) ->
    # Returns the tab object for tab_id if exists, else, undefined
    #
    # Non reactive
    return @_grid_controls_tabs[tab_id]

  # getTab: (tab_id) ->
  #   # The reason we don't implement this function and force the user
  #   # to go through getAllTabs() is that we want to make it clear that
  #   # changes to any tab will trigger reactivity, and not only to this
  #   # tab.

  addTab: (tab_id, options) ->
    # Adds a grid control tab to the mux.
    #
    # tab_id: is an arbitrary string chosen by the
    # developer, which can be used later to refer to that
    # grid control tab.
    #
    # options structure:
    # {
    #   # the grid control options we use to initiate the
    #   grid_control_options: {}
    #   removable: true by default, if set to false removeTab
    #              will throw exception if requested for this
    #              tab.
    #
    #   load_on_init: false by default, if set to true. We will
    #                 call @loadTab(tab_id) immediately after adding the
    #                 tab
    #
    #   activate_on_init: false by default, if set to true. We will
    #                     call @activateTab(tab_id) immediately after adding
    #                     the tab. Note, that since @activateTab() call @loadTab()
    #                     if the tab isn't loaded yet, no need to set load_on_init
    #                     to true if activate_on_init is true.
    # }
    #

    default_options =
      removable: true
      load_on_init: false
      activate_on_init: false

    options = _.extend {}, default_options, options

    if @getTabNonReactive(tab_id)?
      throw @_error("id-already-exists")

    if not (grid_control_options = options.grid_control_options)?
      throw @_error("missing-option", "Missing option 'grid_control_options'")

    grid_control_options = _.extend {}, grid_control_options # Make a shallow copy of grid_control_options

    if @_shared_grid_data_core?
      Meteor._ensure(grid_control_options, "grid_data_options")

      if not grid_control_options.grid_data_options.grid_data_core?
        grid_control_options.grid_data_options.grid_data_core = @_shared_grid_data_core
      else
        @logger.warn "Tab #{tab_id} grid control options includes options: grid_data_options.grid_data_core, avoid using Multiplexer's grid-data-core"

    @_grid_controls_tabs[tab_id] =
      tab_id: tab_id
      grid_control_options: grid_control_options
      grid_control: null
      state: "off"
      active: false
      removable: options.removable
      grid_control_container: null

    @_grid_controls_tabs_dependency.changed()
    @logger.debug "Tab #{tab_id} added"

    if options.load_on_init
      @loadTab(tab_id)

    if options.activate_on_init
      @activateTab(tab_id)

    return

  isTabLoaded: (tab_id) ->
    if not (tab = @getTabNonReactive(tab_id))?
      throw @_error("unknown-tab-id")

    return tab.grid_control_container?

  loadTab: (tab_id) ->
    # Loads tab_id's GridControl
    #
    # Important! not to be confused with activateTab()

    if not (tab = @getTabNonReactive(tab_id))?
      throw @_error("unknown-tab-id")

    if @isTabLoaded(tab_id)
      @logger.debug "Tab #{tab_id} already loaded, nothing to do"

      return

    tab.grid_control_container =
      $("<div id='grid-control-#{tab_id}' class='grid-control-tab'></div>")

    $(@container).append(tab.grid_control_container)

    grid_control = Tracker.nonreactive ->
      # We don't want the encolsing computation to trigger GC's invalidation
      # destroy procedures. Once time to destroy will come, we'll do it in:
      # @unloadTab or @destroy()
      return new GridControl tab.grid_control_options, tab.grid_control_container

    tab.state = "loading"
    tab.grid_control = grid_control
    @_grid_controls_tabs_dependency.changed()

    grid_control.once "ready", =>

      if (Tracker.nonreactive => @isItemsSubscriptionReady())
        tab.state = "ready"

        @emit "tab-ready", tab
      else
        tab.state = "loading-waiting-subscription"

      @_grid_controls_tabs_dependency.changed()

    return

  unloadTab: (tab_id, _force=false) ->
    # Unloads tab_id's GridControl
    #
    # * state will turn to "off"
    # * Tab's grid control will destroy
    # * grid_control will set to null
    # * grid control container will remove
    #
    # We don't allow unloading of active tabs
    #
    # Important! not to be confused with removeTab()
    #
    # _force should be used only by the @destroy
    # procedures

    if not (tab = @getTabNonReactive(tab_id))?
      throw @_error("unknown-tab-id")

    if not @isTabLoaded(tab_id)
      @logger.debug "Tab #{tab_id} isn't loaded, nothing to do"

      return

    if tab.active == true and _force != true
      throw @_error("cant-unload-active-tab")

    @emit "tab-unload", tab

    # Reset state
    tab.state = "off"

    # Destroy gc
    if (grid_control = tab.grid_control)?
      grid_control.destroy()
    tab.grid_control = null

    # Remove container
    tab.grid_control_container.remove()
    tab.grid_control_container = null

    @_grid_controls_tabs_dependency.changed()

    return

  removeTab: (tab_id, _force=false) ->
    # remove tab_id from the mux
    #
    # * Active tabs can't be removed (Change to other tab first)
    # * Tabs that were added with the "removable" option set to false
    # can't be removed
    #
    # _force should be used only by the @destroy
    # procedures

    if not (tab = @getTabNonReactive(tab_id))?
      throw @_error("unknown-tab-id")

    if (tab.active == true or tab.removable == false) and _force != true
      throw @_error("cant-remove-tab")

    @unloadTab(tab_id, _force)

    delete @_grid_controls_tabs[tab_id]

    @_grid_controls_tabs_dependency.changed()

  getActiveTabNonReactive: ->
    # Return the tab object of the active tab or null,
    # if there's no active tab
    for tab_id, tab of @getAllTabsNonReactive()
      if tab.active
        return tab

    return null

  getActiveTab: ->
    # A reactive resource, invalidates only when
    # the current active tab changes.
    #
    # Make sure to read 'Main drawback of getSync()'
    # in computed-reactive-var.coffee
    return @_current_active_tab_crv.getSync()

  activateTab: (new_tab_id) ->
    if not (new_active_tab = @getTabNonReactive(new_tab_id))?
      throw @_error("unknown-tab-id")

    current_active_tab = @getActiveTabNonReactive()

    if current_active_tab isnt null
      if new_tab_id == current_active_tab.tab_id
        @logger.debug "Tab #{new_tab_id} already activated, nothing to do"

        return

      current_active_tab.active = false
      current_active_tab.grid_control_container.removeClass("active")

    if not @isTabLoaded(new_tab_id)
      @loadTab(new_tab_id) # Load the tab if it isn't loaded already

    new_active_tab.active = true
    new_active_tab.grid_control_container.addClass("active")

    @_grid_controls_tabs_dependency.changed()

  _stopSetPathTabReadyTracker: ->
    # Stop any pending setPath autoruns
    if (current_autorun = @_setPathAutorun)?
      if not current_autorun.stopped
        current_autorun.stop()

  setPath: (path_array) ->
    # Activates tab_id, if it isn't yet, and set its path to the
    # requested path once ready
    #
    # If tab_id doesn't exist will log error.
    # If path doesn't exist in requrested tab_id no indication will be given
    # and will fail silently.

    current_path = Tracker.nonreactive => @getPath()
    if JustdoHelpers.jsonComp(current_path, path_array)
      @logger.debug "setPath: requested path already set"

      return

    [tab_id, path] = path_array 

    if not @getTabNonReactive(tab_id)?
      @logger.error "Unknown tab"

      return

    if not @_ongoing_setPath
      @logger.debug "setPath: turning on ongoing_setPath state"
      # If there's @_ongoing_setPath we are already in
      # a non-completed setPath process state, hence,
      # no need to change state to @_ongoing_setPath
      @_pre_setPath_path = Tracker.nonreactive => @getPath() # must be called before, @_ongoing_setPath = true !
      @_ongoing_setPath = true
      @_ongoing_setPath_dependency.changed()

    turnOffOngoingSetPath = =>
      @logger.debug "setPath: turning off ongoing_setPath state"

      @_pre_setPath_path = null
      @_ongoing_setPath = false
      @_ongoing_setPath_dependency.changed()

    # Activate tab_id
    @activateTab(tab_id)

    # Setup an autorun that waits for the tab to become
    # ready
    @_stopSetPathTabReadyTracker()

    Tracker.nonreactive =>
      @_setPathAutorun = Tracker.autorun (c) =>
        tabs = @getAllTabs() # The only reactive resource in this comp
        tab = tabs[tab_id]

        if tab.active == false
          @logger.debug "setPath: active tab changed, cancelling setPath request"

          c.stop()

          turnOffOngoingSetPath()

          return

        if tab.state == "ready"
          if path?
            # If there's a path to activate, activate it
            grid_control = tab.grid_control

            grid_control.forceItemsPassCurrentFilter GridData.helpers.getPathItemId(path)
            if grid_control.activatePath path, 0, {smart_guess: true}
              @logger.debug "setPath: path #{path} (or alternative) of tab #{tab_id} activated"
            else
              @logger.debug "setPath: path #{path} is unknown"
          else
            @logger.debug "setPath: tab #{tab_id} activated (only tab specified, no specific path to activate)"

          c.stop()

          turnOffOngoingSetPath()

          return

  getPath: ->
    # Returns an array: [tab_id, path]
    #
    # Reactive resource. Reactivity isolated to the
    # actual returned value, using CRVs.
    #
    # Make sure to read 'Main drawback of getSync()'
    # in computed-reactive-var.coffee
    #
    # Notes on returned value:
    #
    # * If there's no active tab, will hold [null, null].
    # * If there's tab, but no active path when setPath
    # is called will hold [tab_id, null].
    # * Regards non-ready tabs as having no path, will
    # return [tab_id, null], as long as the grid isn't
    # ready.
    # * As long as there's an ongoing setPath, will return
    # the path before setPath was called (reactivity recognizes
    # completion of setPath, and will trigger invalidation upon
    # completion, due to CRVs, only if value changed).

    return @_current_path_crv.getSync()

  getActiveGridControl: (require_ready=false) ->
    # Returns the grid control object of the current active tab
    #
    # if require_active is true, getActiveGridControl will return
    # null as long as the active tab isn't ready - read about
    # tab's ready state in client/init.coffee
    # if require_active is false, will return the grid_control
    # regardless of state - note that grid_control might be
    # null, if tab didn't load the grid_control yet.
    #
    # Reactive resource. Reactivity isolated to the
    # actual returned value, using CRVs.
    #
    # Make sure to read 'Main drawback of getSync()'
    # in computed-reactive-var.coffee

    if not require_ready
      @_current_grid_control_crv.getSync()
    else
      @_current_grid_control_if_ready_crv.getSync()

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    for tab_id of @getAllTabsNonReactive()
      @removeTab(tab_id, true)

    @container.removeClass "grid-control-mux"

    @subscription_ready_tracker.stop() # defined in client/init.coffee

    @destroyComputedReactiveVars()

    @_stopSetPathTabReadyTracker()

    if @_shared_grid_data_core?
      @_shared_grid_data_core.destroy()

    @destroyed = true

    @logger.debug "Destroyed"