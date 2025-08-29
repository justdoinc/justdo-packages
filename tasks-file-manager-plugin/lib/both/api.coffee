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
        getFilesByIds: (file_ids) ->
          normalized_files = []

          query = 
            files:
              $elemMatch:
                id: 
                  $in: file_ids
          query_options = 
            fields:
              "files.id": 1
              "files.type": 1
              "files.title": 1
              "files.size": 1
              "files.date_uploaded": 1
              "files.user_uploaded": 1
          APP.collections[self._getCollectionName()].find(query, query_options).forEach (doc) ->
            files = _.filter doc.files, (file) -> file.id in file_ids
            files = _.map files, (file) ->
              ret = 
                _id: file.id
                type: file.type
                name: file.title
                size: file.size
                uploaded_at: file.date_uploaded
                uploaded_by: file.user_uploaded
              return ret
            normalized_files = normalized_files.concat files

          return normalized_files
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

          return APP.collections[self._getCollectionName()].findOne(query, query_options)?

        instance: self.tasks_file_manager

      if self._getEnvSpecificFsOptions?
        tasks_files_driver_options = _.extend tasks_files_driver_options, self._getEnvSpecificFsOptions()

      APP.justdo_file_interface.registerFs "#{TasksFileManagerPlugin.fs_id}-tasks-files", tasks_files_driver_options

      return

    return

  _getCollectionName: ->
    if Meteor.isClient
      return "TasksAugmentedFields"

    if Meteor.isServer
      return "Tasks"
