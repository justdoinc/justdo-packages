_.extend JustdoFilesDriver.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @_drivers = {}
    @_default_driver_id = null

    @setupRouter()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  # Register a driver
  registerDriverOptionsSchema: new SimpleSchema JustdoFilesDriver.both_register_driver_options_schema_properties
  registerDriver: (driver_id, options) ->
    if not driver_id?
      throw @_error "missing-argument", "Driver ID is required"

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @registerDriverOptionsSchema,
        options,
        {throw_on_error: true}
      )
    options = cleaned_val  

    @_drivers[driver_id] = options
    
    if not @getDefaultDriverId()?
      @setDefaultDriverId driver_id
      
    return

  setDefaultDriverId: (driver_id) ->
    if not @_drivers[driver_id]?
      throw @_error "not-supported",  "Driver '#{driver_id}' not found. Please register it first."

    @_default_driver_id = driver_id
    return
  
  getDefaultDriverId: ->
    return @_default_driver_id

  # Connect to a driver and return connection object
  connect: (driver_id) ->
    if not driver_id?
      driver_id = @getDefaultDriverId()
    
    if not (driver = @_drivers[driver_id])?
      throw @_error "not-supported", "Driver \"#{driver_id}\" not found"

    return driver
