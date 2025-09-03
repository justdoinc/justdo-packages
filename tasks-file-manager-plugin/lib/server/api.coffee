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
        ret = self.tasks_file_manager.uploadAndRegisterFile task_id, file_blob, filename, mimetype, metadata, user_id
        ret.name = ret.title
        ret._id = ret.id
        return ret
    return ret