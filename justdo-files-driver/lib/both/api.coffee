_.extend JustdoFilesDriver.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

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

  setDefaultDriverId: (driver_id) ->
    if not @_drivers[driver_id]?
      throw @_error "not-supported",  "Driver '#{driver_id}' not found. Please register it first."

    @_default_driver_id = driver_id
    return
  
  getDefaultDriverId: ->
    return @_default_driver_id

