_.extend TasksFileManagerPlugin.prototype,
  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
  
  _getEnvSpecificFsOptions: ->
    self = @
    
    ret = {}

    return ret