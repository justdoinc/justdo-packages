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

      tfm_GetPreviewDownloadLink: (task_id, file_id, version, options) ->
        check task_id, String
        check file_id, String
        check version, Number
        check options, Object

        # We want to unblock so if there are multi files that we need to generate
        # preview files for (a process that can take 100s of ms) we won't wait for
        # them to be generated one by one, but will trigger the generation of all
        # at once.
        @unblock()

        self.requireLogin @userId

        return self.getPreviewDownloadLink task_id, file_id, version, options, @userId

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
