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
      uploadFile: (task_id, file_blob, filename, mimetype, metadata, user_id) ->
        return await self.tasks_file_manager.uploadAndRegisterFile options.task_id, file, options.filename, options.mimetype, options.metadata, user_id
      downloadFile: (options, cb) ->
        self.tasks_file_manager.downloadFile options.task_id, options.file_id, cb
        return
    return ret