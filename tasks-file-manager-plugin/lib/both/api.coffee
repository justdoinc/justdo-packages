_.extend TasksFileManagerPlugin.prototype,
  _registerFilesDriver: ->
    self = @

    tasks_files_driver_options = 
      getFileSizeLimit: -> 
        _env = env
        if Meteor.isServer
          _env = process.env

        return _env.FILESTACK_MAX_FILE_SIZE_BYTES
      getTaskFileLink: (file_id, task_id) ->
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
      isTaskFileExists: (file_id, task_id) ->
        query = 
          _id: task_id
          files:
            $elemMatch:
              id: file_id
        query_options = 
          fields:
            _id: 1

        return APP.collections[self._getCollectionName()].findOne(query, query_options)?
      isFileTypePreviewable: (file_type) ->
        return self.isFileTypePreviewable file_type
      isUserAllowedToUploadTaskFile: (task_id, user_id) ->
        permissions = [
          "task-field-edit.#{TasksFileManager.files_count_field_id}",
          "task-field-edit.files"
        ]
        return APP.justdo_permissions.checkTaskPermissions permissions, task_id, user_id

      instance: self.tasks_file_manager

    if self._getEnvSpecificFsOptions?
      tasks_files_driver_options = _.extend tasks_files_driver_options, self._getEnvSpecificFsOptions()

    APP.justdo_file_interface.registerFs "#{TasksFileManagerPlugin.fs_id}-tasks-files", tasks_files_driver_options

    return

  _getCollectionName: ->
    if Meteor.isClient
      return "TasksAugmentedFields"

    if Meteor.isServer
      return "Tasks"

  _getPreviewableFileTypes: ->
    conv_matrix = @tasks_file_manager.getConversionMartix()
    preview_supported_formats = _.union conv_matrix["pdf"], conv_matrix["jpg"]

    return preview_supported_formats

  isFileTypePreviewable: (file_type) ->
    previewable_file_types = @_getPreviewableFileTypes()

    return (file_type in previewable_file_types) or (file_type.indexOf("video/") is 0)