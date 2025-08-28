_.extend TasksFileManagerPlugin.prototype,
  _registerFilesDriver: ->
    self = @

    if Meteor.isClient
      await @filestackReadyDfd.promise()

    APP.getEnv (env) ->
      tasks_files_driver_options = 
        getFileSizeLimit: -> env.FILESTACK_MAX_FILE_SIZE_BYTES
        getFileLink: (options, cb) ->
          try
            link = self.tasks_file_manager.getFileDownloadPath options.task_id, options.file_id
          catch err
            cb err
            return

          cb null, link

          return
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

          collection_name = "TasksAugmentedFields"
          if Meteor.isServer
            collection_name = "Tasks"

          return APP.collections[collection_name].findOne(query, query_options)?

        instance: self.tasks_file_manager

      if self._getEnvSpecificFsOptions?
        tasks_files_driver_options = _.extend tasks_files_driver_options, self._getEnvSpecificFsOptions()

      APP.justdo_file_interface.registerFs "#{TasksFileManagerPlugin.fs_id}-tasks-files", tasks_files_driver_options

      return

    return

