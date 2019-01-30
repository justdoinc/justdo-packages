_.extend JustdoAnalytics.prototype,
  _initStorage: ->
    # If you move this from here, update both/init.coffee schema comment
    # for it as well
    @storage_types = _.uniq(@options.storage.split(","))

    @storage_drivers = {}

    for storage_type in @storage_types
      if not (StorageDriver = JustdoAnalytics.StorageDrivers[storage_type])?
        throw @_error("unknown-stoarge-type", "Unknown stoarge type #{storage_type}")

      @storage_drivers[storage_type] = new StorageDriver()

    return