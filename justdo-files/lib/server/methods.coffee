_.extend JustdoFiles.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "jdfRemoveFile": (file_id) ->
        check file_id, String

        self.removeFile(file_id, @userId)

        return

      "jdfRenameFile": (file_id, new_filename) ->
        check file_id, String
        
        self.renameFile file_id, new_filename, @userId

        return

      "jdfRemoveOldAvatars": (options) ->
        check @userId, String

        self.removeOldAvatars options, @userId

        return

    return
