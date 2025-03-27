_.extend JustdoHelpers,
  ###
  Creates a new GridControl instance with predefined options from a given tab in a GridControlMux

  @param {Object} options - Configuration options for creating the GridControl
    @param {String} [options.tab_id="main"] - The tab_id to get grid_control_options from
    @param {jQuery|String} options.container - The container element or selector for the new GridControl
    @param {Object} [options.sections_state] - Initial sections state to set after GridControl is created
    @param {String} [options.root_item_id] - Item ID to set as root and activate (shorthand for sections_state: {global: {"root-item": root_item_id}})
    @param {Boolean} [options.delete_grid_data_options=true] - Whether to delete grid_data_options from copied grid_control_options
    @param {Object} [options.override_options] - Additional options to override the ones from the GridControlMux tab
    @param {Function} [options.onInit] - Callback function triggered on "init" event
    @param {Function} [options.onReady] - Callback function triggered on "ready" event

  @return {GridControl} - Newly created GridControl instance
  ###
  createGridControl: (options = {}) ->
    # Default tab_id to "main" if not specified
    tab_id = options.tab_id or "main"
    
    # Get the main grid control mux
    project_page_module = APP.modules.project_page
    main_grid_control_mux = project_page_module.getGridControlMux()
    
    # Get grid_control_options from the specified tab
    tab_grid_control_options = _.extend {}, main_grid_control_mux.getTabNonReactive(tab_id)?.grid_control_options

    # If no tab found, throw an error
    if not tab_grid_control_options?
      throw new Meteor.Error("invalid-argument", "Tab '#{tab_id}' not found in GridControlMux")
    
    # Delete grid_data_options if specified (default: true)
    if options.delete_grid_data_options isnt false
      delete tab_grid_control_options.grid_data_options
    
    # Override with any provided options
    if options.override_options
      _.extend tab_grid_control_options, options.override_options
    
    # Get container element (required)
    if not (container = options.container)?
      throw new Meteor.Error("missing-argument", "Container element is required for createGridControl")
    
    # Create the GridControl instance
    grid_control = new GridControl tab_grid_control_options, container
    grid_data = null
    
    # Set up event handlers for the grid control
    grid_control.once "init", ->
      grid_data = grid_control._grid_data
      
      # If root_item_id is provided, use it to set sections state
      if options.root_item_id
        grid_data.setSectionsState {global: {"root-item": options.root_item_id}}, true, true
      # Or use provided sections_state if any
      else if options.sections_state
        grid_data.setSectionsState options.sections_state, true, true
      
      # Call onInit callback if provided
      if _.isFunction options.onInit
        options.onInit.call @, grid_data
      
      return

    grid_control.once "ready", ->
      # If root_item_id is provided, activate it
      if options.root_item_id
        grid_control.activateCollectionItemId options.root_item_id, 0, {smart_guess: true}
        path = grid_data.getCollectionItemIdPath options.root_item_id
        if path
          grid_data.expandPath path
      
      # Call onReady callback if provided
      if _.isFunction options.onReady
        options.onReady.call @, grid_data
      
      return
    
    return grid_control 