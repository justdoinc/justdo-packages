_.extend JustdoProjectPane.prototype,
  _immediateInit: ->
    @_tabs_definitions = {}
    @_tabs_definitions_dep = new Tracker.Dependency()

    @_user_preferrence_dep = new Tracker.Dependency()

    @_last_applied_state = undefined

    @_full_screen_rv = new ReactiveVar false

    @_pane_state_tracker = undefined
    @_setupPaneUpdater()

    return

  _deferredInit: ->
    if @destroyed
      return

    # The code below closes the project pane upon switching JustDo,
    # when the performance issue is addressed, this section can be remoed.
    @previous_proj_id = JD.activeJustdoId()
    @project_pane_auto_collapse_handler = Tracker.autorun =>
      # Collapses project pane upon swiching JustDo.
      if @previous_proj_id isnt JD.activeJustdoId()
        @collapse()
        @previous_proj_id = JD.activeJustdoId()

      return
    @onDestroy =>
      @project_pane_auto_collapse_handler.stop()
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
      APP.justdo_split_view.size.set JustdoProjectPane.collapsed_height

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
      if @_full_screen_rv.get()
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

  #
  # Tabs registration
  #
  getTabsDefinitions: ->
    @_tabs_definitions_dep.depend()

    return @_tabs_definitions

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

  isFullScreen: -> @_full_screen_rv.get()

  enterFullScreen: -> 
    @_full_screen_rv.set true
    $(".app-wrapper").addClass "no-scroll"
    return

  exitFullScreen: -> 
    $(".app-wrapper").removeClass "no-scroll"
    @_full_screen_rv.set false
    return

  toggleFullScreen: -> 
    is_full_screen = Tracker.nonreactive => @isFullScreen()
    if is_full_screen
      @exitFullScreen()
    else
      @enterFullScreen()
    return