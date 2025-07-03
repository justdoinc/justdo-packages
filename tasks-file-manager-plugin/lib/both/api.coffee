_.extend TasksFileManagerPlugin.prototype,
  _registerFilesDriver: ->
    self = @

    if Meteor.isClient
      await @filestackReadyDfd.promise()

    APP.getEnv (env) ->
      tasks_files_driver_options = 
        getFileSizeLimit: -> env.FILESTACK_MAX_FILE_SIZE_BYTES
        getFileLink: (options, cb) ->
          task_id = options.task_id
          file_id = options.file_id

          return self.tasks_file_manager.getFileDownloadPath task_id, file_id
        isFileExists: (options) ->
          task_id = options.task_id
          file_id = options.file_id

          query = 
            _id: task_id
            files:
              $elemMatch:
                id: file_id
          query_options = 
            fields:
              _id: 1

          exists = APP.collections.Tasks.findOne(query, query_options)?
          cb null, exists
          return
        instance: self.tasks_file_manager

      if self._getEnvSpecificFsOptions?
        tasks_files_driver_options = _.extend tasks_files_driver_options, self._getEnvSpecificFsOptions()

      APP.justdo_file_interface.registerFs "#{TasksFileManagerPlugin.fs_id}-tasks-files", tasks_files_driver_options

      return

    return

