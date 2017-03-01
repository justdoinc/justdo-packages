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
    # @_current_active_tab_crv
    #
    # Invalidates only when active tab changes
    #
    @_current_active_tab_crv =
      newComputedReactiveVar "current_active_tab", getActiveTabOrNull,
        # options
        reactiveVarEqualsFunc: isIdentical

    #
    # @_current_active_tab_state_sensitive_crv
    #
    # Invalidates when active tab changes and when
    # the active tab state is changing
    #
    _current_tab_last_state = null
    @_current_active_tab_state_sensitive_crv =
      newComputedReactiveVar "current_active_tab_state", getActiveTabOrNull,
        # options
        reactiveVarEqualsFunc: (a, b) ->
          if not a? and not b?
            # Init state both null/undefined, don't invalidate
            return true

          # If different objects, then for sure active tab
          # is different, and invalidation required
          if a isnt b
            # Since we want  to invalidate on state change, and we change the
            # same tab object when the state change, the only way, to
            # recognize whether the state changed is to compare it to a
            # reference we keep to the last state
            _current_tab_last_state = if b? then b.state else null

            return false

          # Otherwise, only if one of the tab state changed trigger
          # invalidation
          if b.state != _current_tab_last_state
            _current_tab_last_state = b.state

            return false

          return true

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
    @_current_active_tab_state_sensitive_crv.stop()
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
    #   # the grid control options we use to initiate the tab's grid control
    #   # note that these options will take precedence over options defined
    #   # in the grid control mux's options.shared_grid_control_options option
    #   # (kept after validation under @_shared_grid_control_options)
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
    #
    #   tabTitleGenerator: undefined by default. Can be undefined/String/Function.
    #                      Affects the value returned by tab's name() method under @_grid_controls_tabs: 
    #                      * If is undefined: the method will return the tab_id
    #                      * If is String the method will return that String.
    #                      * If is a function, that function will be called with
    #                        the GridControlMux object as its `this` and the tab_id as its first argument.
    #                        The function should return the string that will be used for the tab title.
    #
    #                        If the returned value isn't a String we'll print the default
    #                        title (as if undefined was set as tabTitleGenerator).
    #
    #                        Tip: you can use @getTabGridControlSectionsState(tab_id) to
    #                        get the current grid control sections state and set the tab
    #                        title accordingly.
    #
    #                        tabTitleGenerator: (tab_id) ->
    #                           sections_state = @getTabGridControlSectionsState(tab_id)
    # }
    #

    default_options =
      removable: true
      load_on_init: false
      activate_on_init: false
      tabTitleGenerator: undefined

    options = _.extend {}, default_options, options

    if @getTabNonReactive(tab_id)?
      throw @_error("id-already-exists")

    if not (grid_control_options = options.grid_control_options)?
      throw @_error("missing-option", "Missing option 'grid_control_options'")

    grid_control_options = _.extend {}, @_shared_grid_control_options, grid_control_options # Merge with @_shared_grid_control_options

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
      getTabTitle: =>
        if (tabTitleGenerator = options.tabTitleGenerator)?
          if _.isString tabTitleGenerator
            return tabTitleGenerator          
          else if _.isFunction tabTitleGenerator
            if _.isString(title = tabTitleGenerator.call(@, tab_id))
              return title
            else
              @logger.warn "tab's tabTitleGenerator() returned non-string value"
          else
            @logger.warn "We don't support tabTitleGenerator of type: #{typeof tabTitleGenerator}"

        return tab_id

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

    @emit "grid-control-created", tab

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
    # IMPORTANT, doesn't invalidate on state changes,
    # check @getActiveTabState() if needed
    #
    # Make sure to read 'Main drawback of getSync()'
    # in computed-reactive-var.coffee
    return @_current_active_tab_crv.getSync()

  getActiveTabState: ->
    # Returns the active tab state, or null if there's
    # no active tab
    #
    # A reactive resource, invalidates when
    # the current active tab changes, and,
    # when the current active tab state changes.
    #
    # Make sure to read 'Main drawback of getSync()'
    # in computed-reactive-var.coffee
    active_tab = @_current_active_tab_state_sensitive_crv.getSync()

    if not active_tab?
      return null

    return active_tab.state

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

  getActiveGridControlSectionsState: ->
    # Returns the current grid's sections state object
    if not (gc = @getActiveGridControl(true))?
      return null
    else
      return gc._grid_data.exportSectionsState()

  setActiveGridControlSectionsState: (new_sections_state, replace) ->
    # Updates the state of the current grid's sections
    # state object
    #
    # replace argument is documented under grid-data package setSectionsState()
    # see file named: grid-sections.coffee (note replace is true by default)
    #
    # If the active grid control is not ready, the new_sections_state will be set once the 'ready' event will be emitted by the grid
    # If there's no active grid control, do nothing 

    gc = null
    setSectionsState = =>
      gc._grid_data.setSectionsState(new_sections_state)

      @logger.debug("setActiveGridControlSectionsState: updated")

    return Tracker.nonreactive =>
      if (gc = @getActiveGridControl(true))?
        # Grid control is ready, load
        setSectionsState()

        return
      else
        if not (gc = @getActiveGridControl())?
          @logger.debug("setActiveGridControlSectionsState: Can't update active sections state: No active grid")
          return

        @logger.debug("setActiveGridControlSectionsState: grid not ready yet, waiting")
        gc.once "ready", =>
          @logger.debug("setActiveGridControlSectionsState: grid ready")

          setSectionsState()

        return

  getTabGridControlNonReactive: (tab_id, require_ready=false) ->
    # Similar output to @getActiveGridControl() for any tab_id
    # Non Reactive

    tab = @getTabNonReactive(tab_id)
    if not require_ready or tab.state == "ready"
      return tab.grid_control

    return null

  getTabGridControlSectionsState: (tab_id) ->
    # Returns the tab_id's grid's sections state object, or null if
    # tab_id's doesn't have grid_control or if it isn't ready
    if not (gc = @getTabGridControlNonReactive(tab_id, true))?
      return null
    else
      return gc._grid_data.exportSectionsState()

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