_.extend JustdoProjectPane.prototype,
  _immediateInit: ->
    @_tabs_definitions = {}
    @_tabs_definitions_dep = new Tracker.Dependency()

    @_user_preferrence_dep = new Tracker.Dependency()

    @_last_applied_state = undefined

    @_full_screen_rv = new ReactiveVar false

    @_collapsed_height_rv = new ReactiveVar JustdoProjectPane.collapsed_height
    
    @_pane_state_tracker = undefined
    @_setupPaneUpdater()

    @_set_fullscreen_state_on_project_load_tracker = undefined
    @_setupDefaultFullScreenStateTracker()

    @_project_pane_auto_collapse_handler = undefined
    @_setupProjectPaneAutoCollapseHandler()

    @_setupEventHandlers()

    @_setupHashRequests()

    @_registerMobileTab()

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  _setupHashRequests: ->
    APP.hash_requests_handler.addRequestHandler "expand-project-pane", (args) =>
      if not (tab_id = args["tab-id"])?
        # We use `@logger.error` instead of `throw @_error` here to allow the hash request handler to continue removing the hash.
        @logger.error "not-supported", "expand-project-pane hash request received with no tab-id argument"
        return
        
      if not (tab_definition = @getTabDefinitionById(tab_id))?
        # It's possible that this handler is called when none of the tabs are registered.
        # In that case, we should return {keep_hash: true} to keep the hash to allow next re-run
        # triggered by the reactivity of `getTabDefinitionById` to process the hash again.
        return {keep_hash: true}

      Tracker.nonreactive =>
        @setActiveTab(tab_id)
        @expand()
        tab_definition.hashRequestHandler?(args)

        return
        
      return
  
  _setupEventHandlers: ->
    APP.on "grid-control-created", (gc) =>
      # Setup event handler to exit full screen mode when a row is activated in the main grid
      if gc.getDomain() isnt "project-page-main-grid"
        return

      gc.on "pre-activate-row", =>
        if @isFullScreen()
          @exitFullScreen()
        return
        
      return

    return

  _setupProjectPaneAutoCollapseHandler: ->
    # The main purpose of this tracker is to close the project pane upon switching JustDo.
    # However, currently it's also used to ensure that the project pane is closed upon first loading a project:
    # When `_setupProjectPaneAutoCollapseHandler` is called inside `immediateInit`, 
    # `JD.activeJustdoId()` would always return undefined, thus ensuring that the project pane is closed upon first loading a project.
    if @_project_pane_auto_collapse_handler?
      return

    @previous_proj_id = JD.activeJustdoId()
    @project_pane_auto_collapse_handler = Tracker.autorun =>
      # Collapses project pane upon swiching JustDo.
      if @previous_proj_id isnt (cur_proj_id = JD.activeJustdoId())
        @collapse()
        @previous_proj_id = cur_proj_id

      return

    @onDestroy =>
      @project_pane_auto_collapse_handler.stop()
      @project_pane_auto_collapse_handler = null
      return

    return

  _registerMobileTab: ->
    APP.justdo_pwa.registerMobileTab "project-pane",
      label: "project_pane_label"
      order: 400
      icon: "sidebar"
      listingCondition: => 
        # Require active justdo and the project pane to be enabled
        return JD.activeJustdoId()? and not (@getPaneState()?.disabled)
      onActivate: =>
        @expand()
        @enterFullScreen()
        return
      onDeactivate: =>
        @collapse()
        return
        
    return

  _pane_state_schema: new SimpleSchema
    active_tab_id:
      type: String
      regEx: /^[a-z-]+$/i
      optional: true
    expand_height:
      type: Number
      optional: true
      decimal: true
    is_expanded:
      type: Boolean
      optional: true

  _default_pane_state:
    expand_height: 250
    is_expanded: false

  #
  # User preferrence related methods
  #
  amplify_state_key_prefix: "jd-project-pane-state"

  _getAmplifyStateKey: -> @amplify_state_key_prefix + "::" + Meteor.userId()

  getUserPreferredPaneState: ->
    # The preference is taken into account only if other constrains will permit
    # its application.

    @_user_preferrence_dep.depend()

    return amplify.store(@_getAmplifyStateKey()) or {}

  setUserPreferredPaneState: (changes_to_state) ->
    # The preference is taken into account only if other constrains will permit
    # its application.
    #
    # If a preferred state is already stored for the user changes_to_state
    # will be merged to it - not replace it.

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_pane_state_schema,
        changes_to_state,
        {self: @, throw_on_error: true}
      )
    changes_to_state = cleaned_val

    if (active_tab_id = changes_to_state.active_tab_id)?
      if active_tab_id not of @getTabsDefinitions()
        throw @_error "unknown-tab-id"

    existing_preferred_state = Tracker.nonreactive => @getUserPreferredPaneState()

    # Check whether there are any actual changes
    _changes_to_state_without_existing = _.extend({}, changes_to_state)
    for option, val of _changes_to_state_without_existing
      if existing_preferred_state[option] == val
        delete _changes_to_state_without_existing[option]
    if _.isEmpty _changes_to_state_without_existing
      # Nothing to do.
      return

    new_state = _.extend existing_preferred_state, changes_to_state
    try
      # If the following fails, it means that the existing preferred state isn't
      # in line with the pane state schema - if that will happen we will ignore
      # it and will use only the changes_to_state as the new state.
      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          @_pane_state_schema,
          new_state,
          {self: @, throw_on_error: true}
        )
      new_state = cleaned_val
    catch e
      @logger.warn "invalid-stored-state", "Invalid state found in storage, ignored and overridened."

      new_state = changes_to_state

    amplify.store(@_getAmplifyStateKey(), new_state)

    @_user_preferrence_dep.changed()

    # Don't wait for the reactive process of @_pane_state_tracker to call @_applyCurrentPaneState()
    #
    # It does means that @_applyCurrentPaneState will be called twice, but @_applyCurrentPaneState()
    # has a mechanism to ignore update of state that it already applied, so doesn't realy matter.
    @_applyCurrentPaneState()

    return

  #
  # State management/application
  #
  _applyCurrentPaneState: ->
    pane_state_to_apply = Tracker.nonreactive => @getPaneState()

    if not @_last_applied_state?
      @_last_applied_state = {}

    changed_state_options = _.extend {}, pane_state_to_apply
    for option, val of changed_state_options
      if @_last_applied_state[option] == val
        delete changed_state_options[option]

    if _.isEmpty changed_state_options
      return

    @_last_applied_state = pane_state_to_apply

    if changed_state_options.disabled is true
      @_destroyPane()

      return

    if changed_state_options.disabled is false
      @_installPane()

    if changed_state_options.is_expanded is true
      APP.justdo_split_view.size.set pane_state_to_apply.expand_height

    if changed_state_options.is_expanded is false
      APP.justdo_split_view.size.set @getCollapsedHeight()

    if changed_state_options.expand_height?
      APP.justdo_split_view.size.set changed_state_options.expand_height

    return

  _installPane: ->
    APP.justdo_split_view.enabled.set(true)
    APP.justdo_split_view.position.set("bottom")
    APP.justdo_split_view.template.set("justdo_project_pane")

    return

  _destroyPane: ->
    APP.justdo_split_view.enabled.set(false)

    return

  getPaneState: ->
    # getPaneState is a high order method, it takes into account:
    #
    #   * Saved state (the user's preferred state)
    #   * The default state
    #   * Display constrains
    #   * The available existing tabs
    #
    # and provides an allowed state for all these constains.

    tabs_definitions = @getTabsDefinitions()

    if _.isEmpty tabs_definitions
      # No tabs are defined - disable the project pane.
      return {disabled: true}

    preferred_state = @getUserPreferredPaneState()

    state = _.extend({}, @_default_pane_state, preferred_state)

    state.disabled = false

    if state.active_tab_id not of tabs_definitions
      # The preferred tab doesn't exist
      delete state.active_tab_id

      state.active_tab_id = @getTabs()[0].tab_id

    if not state.is_expanded
      delete state.expand_height
    else
      window_height =
        APP.modules.main.real_window_dim.get().height # Note, this is a reactive resource
      
      # Note: Full screen support is implemented here instead of get/setUserPreferredPaneState
      # because we don't want to store the full screen state in the user's preferences.
      if @isFullScreen()
        state.full_screen = true
        state.expand_height = window_height - APP.helpers.getGlobalSassVars().navbar_height
      else
        min_height = JustdoProjectPane.min_expanded_height
        max_height = Math.floor(Math.min(window_height * .8, window_height - 55))

        if max_height < min_height
          state.is_expanded = false

          delete state.expand_height

        if state.expand_height < min_height
          state.expand_height = min_height

        if state.expand_height > max_height
          state.expand_height = max_height

    return state

  _setupPaneUpdater: ->
    if @_pane_state_tracker?
      # Already installed, do nothing

      return

    @_pane_state_tracker = Tracker.autorun =>
      @getPaneState() # The reactive resource.

      @_applyCurrentPaneState()

      return

    @onDestroy =>
      @_removePaneUpdater()

      return

    return

  _removePaneUpdater: ->
    if @_pane_state_tracker?
      @_pane_state_tracker.stop()
      @_pane_state_tracker = undefined

      @_destroyPane()
      @_last_applied_state = undefined

    return

  _setupDefaultFullScreenStateTracker: ->
    if @_set_fullscreen_state_on_project_load_tracker?
      return

    # This tracker is responsible for loading the stored full screen state upon first load into a project
    @_set_fullscreen_state_on_project_load_tracker = Tracker.autorun =>
      # For reactivity
      if not (justdo_id = JD.activeJustdoId())?
        return

      @_full_screen_rv.set @getFullScreenAmplifyState()
      return
    
    return

    @onDestroy =>
      @_removeDefaultFullScreenStateTracker()

      return
  
  _removeDefaultFullScreenStateTracker: ->
    if not @_set_fullscreen_state_on_project_load_tracker?
      return

    @_set_fullscreen_state_on_project_load_tracker.stop()
    @_set_fullscreen_state_on_project_load_tracker = undefined

    return
    
  #
  # Tabs registration
  #
  getTabsDefinitions: ->
    @_tabs_definitions_dep.depend()

    return @_tabs_definitions
  
  getTabDefinitionById: (tab_id) ->
    return @getTabsDefinitions()[tab_id]

  _tabDefinitionSchema: new SimpleSchema
    tab_id:
      type: String
      regEx: /^[a-z-]+$/i
    order:
      type: Number
      defaultValue: 100
    tab_template:
      type: String
    tab_label:
      type: String
    hashRequestHandler:
      type: Function
      optional: true
  registerTab: (tab_definition) ->
    # Note that the process permits tab_definition update

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_tabDefinitionSchema,
        tab_definition,
        {self: @, throw_on_error: true}
      )
    tab_definition = cleaned_val

    @_tabs_definitions[tab_definition.tab_id] = tab_definition
    @_tabs_definitions_dep.changed()

    return

  unregisterTab: (tab_id) ->
    if tab_id of @_tabs_definitions
      delete @_tabs_definitions[tab_id]

      @_tabs_definitions_dep.changed()

    return

  getTabs: ->
    # Returns the tabs as array, ordered by to their order
    return _.sortBy _.values(@getTabsDefinitions()), "order"

  #
  # Shortcut methods
  #
  getActiveTabId: -> @getPaneState().active_tab_id

  getActiveTabTemplateName: -> @getTabsDefinitions()[@getActiveTabId()].tab_template

  setActiveTab: (tab_id) -> @setUserPreferredPaneState({active_tab_id: tab_id})

  isExpanded: -> @getPaneState().is_expanded is true

  expand: -> @setUserPreferredPaneState({is_expanded: true})

  collapse: -> @setUserPreferredPaneState({is_expanded: false})

  setHeight: (height) -> @setUserPreferredPaneState({expand_height: height})

  isFullScreen: -> @_full_screen_rv.get() is true

  _generateFullScreenAmplifyKey: -> JustdoProjectPane.full_screen_amplify_key_prefix + "::" + JD.activeJustdoId()

  getFullScreenAmplifyState: -> amplify.store @_generateFullScreenAmplifyKey()

  setFullScreenAmplifyState: (state) -> amplify.store @_generateFullScreenAmplifyKey(), state

  enterFullScreen: -> 
    @setFullScreenAmplifyState true
    @_full_screen_rv.set true
    return

  exitFullScreen: -> 
    @setFullScreenAmplifyState false
    @_full_screen_rv.set false
    return

  toggleFullScreen: -> 
    is_full_screen = Tracker.nonreactive => @isFullScreen()
    if is_full_screen
      @exitFullScreen()
    else
      @enterFullScreen()
    return

  setCollapsedHeight: (height) -> 
    if not _.isNumber(height)
      throw @_error "invalid-argument", "Height is not a number: #{height}"

    @_collapsed_height_rv.set height
    return

  getCollapsedHeight: -> 
    return @_collapsed_height_rv.get()