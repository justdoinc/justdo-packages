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
    
    ret = 
      uploadTaskFile: (task_id, file_blob, filename, mimetype, metadata, user_id) ->
        return await self.tasks_file_manager.uploadAndRegisterFile task_id, file_blob, filename, mimetype, metadata, user_id
    return ret