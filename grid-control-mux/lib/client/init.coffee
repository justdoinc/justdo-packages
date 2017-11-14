_.extend GridControlMux.prototype,
  _immediateInit: ->
    if not (@container = @options.container)?
      throw @_error("missing-option", "You must set the 'container' option")

    if not (@items_subscription = @options.items_subscription)?
      throw @_error("missing-option", "You must set the 'items_subscription' option")

    @container.addClass "grid-control-mux"

    # Holds the definitions of the grid controls tabs held by
    # this multiplexer and their current state.
    #
    # Structure:
    #
    # IMPORTANT, only properties marked with TR below, will
    # trigger reactivity for methods that depends upon
    # @_grid_controls_tabs_dependency .
    # 
    # {
    #   "definition-id": (object) TR when set/remove {
    #     tab_id: NON-TR <- Considered immutable, do not change
    #     grid_control_options: NON-TR [] <- Considered immutable, do not change
    #
    #     grid_control: TR # the GridControl object if one
    #                      # initiated, null otherwise
    #
    #     state: TR (string) off|loading|waiting-subscription|ready
    #                        # off - not loaded
    #                        # loading - grid control didn't finish loading
    #                        # loading-waiting-subscription - grid control finish loading, subscription not ready
    #                        # ready - ready
    #
    #     active: TR (bool) false|true # Will be true if this is the current
    #                                  # GC the Mux is showing
    #
    #     removable: NON-TR (bool) false|true <- Considered immutable, do not change
    #                              # if is false, removeTab() will throw exception if
    #                              # requested for this tab
    #
    #     container: NON-TR (jQuery) if grid control initiated the jQuery obj of the
    #                grid control containing node, otherwise, null
    #   }
    # }
    @_grid_controls_tabs = {}
    @_grid_controls_tabs_dependency = new Tracker.Dependency()

    # If the @options.use_shared_grid_data_core is passed
    # one GridDataCore object will be init by the grid-control-mux
    # and shared among all the GridControl's GridData objects
    @_shared_grid_data_core = null
    if @options.use_shared_grid_data_core == true
      grid_data_core_options = @options.shared_grid_data_core_options
      if not grid_data_core_options.collection?
        throw @_error "missing-option", "If the `use_shared_grid_data_core` option is set to true, you must specify the `shared_grid_data_core_options.collection` option to the collection you want GridDataCore to work with"

      @_shared_grid_data_core = new GridDataCore(grid_data_core_options)

    # options passed to @options.common_grid_control_options will be 
    # set, with secondary precedence to the tab's grid_control_options,
    # to all grid controls created by this grid control mux.
    if @options.shared_grid_control_options? and not _.isObject @options.shared_grid_control_options
      throw @_error("invalid-options", "shared_grid_control_options should be an object")
    @_shared_grid_control_options = @options.shared_grid_control_options or {}

    # If the @options.use_shared_grid_control_custom_fields_manager is passed
    # a GridControlCustomFieldsManager object will be init by the grid-control-mux
    # and will be passed as the grid_control_custom_fields_manager option of all
    # the grid controls of this mux
    @_shared_grid_control_custom_fields_manager = null
    if @options.use_shared_grid_control_custom_fields_manager == true
      shared_grid_control_custom_fields_manager_options = @options.shared_grid_control_custom_fields_manager_options

      @_shared_grid_control_custom_fields_manager = new GridControlCustomFieldsManager(shared_grid_control_custom_fields_manager_options)

    # Read comment for @options.use_shared_grid_control_custom_fields_manager above,
    # this is just the same but for the removed custom fields.
    @_shared_grid_control_removed_custom_fields_manager = null
    if @options.use_shared_grid_control_removed_custom_fields_manager == true
      shared_grid_control_removed_custom_fields_manager_options = @options.shared_grid_control_removed_custom_fields_manager_options

      @_shared_grid_control_removed_custom_fields_manager = new GridControlCustomFieldsManager(shared_grid_control_removed_custom_fields_manager_options)

    # The following is managed by @setPath() used to recognize
    # whether an active setPath is happening to avoid reporting
    # intermediate path changes in the process of getting the
    # requested path activated.
    @_ongoing_setPath = false
    @_ongoing_setPath_dependency = new Tracker.Dependency()
    @_pre_setPath_path = null # * null if there's no ongoing @setPath
                              # will hold array: [tab_id, path]
                              # * Read doc for @getPath() for more details
                              # about path array structure.
                              # * If more then one setPath is called,
                              # will hold the path as it was in the
                              # first call (before any setPath process
                              # began).
                              # * Is set back to null upon @setPath
                              # completion.

    @subscription_state_rv = new ReactiveVar false

    @setupComputedReactiveVars()

    # Once subscription is ready resolve @subscription_dfd
    @subscription_ready_tracker = Tracker.autorun (c) =>
      # wait for subscription to become ready
      if @isItemsSubscriptionReady()
        # Once subscription is ready stop the autorun
        c.stop()

        @subscriptionReadyProcedures()

    return

  _deferredInit: ->
    return