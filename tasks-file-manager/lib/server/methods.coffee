_.extend TasksFileManager.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      tfm_RegisterUploadedFiles: (task_id, files) ->
        check task_id, String
        check files, [
          Match.ObjectIncluding
            url: String
            filename: String
            size: Number
            mimetype: String
        ]

        self.requireLogin @userId

        return self.registerUploadedFiles task_id, files, @userId

      tfm_GetDownloadLink: (task_id, file_id) ->
        check task_id, String
        check file_id, String

        self.requireLogin @userId

        return self.getDownloadLink task_id, file_id, @userId

      tfm_RenameFile: (task_id, file_id, newTitle) ->
        check task_id, String
        check file_id, String
        check newTitle, String

        self.requireLogin @userId

        return self.renameFile task_id, file_id, newTitle, @userId

      tfm_RemoveFile: (task_id, file_id) ->
        check task_id, String
        check file_id, String

        self.requireLogin @userId

        return self.removeFile task_id, file_id, @userId

      tfm_GetUploadPolicy: (task_id) ->
        check task_id, String

        self.requireLogin @userId

        return self.getUploadPolicy task_id, @userId

    return
