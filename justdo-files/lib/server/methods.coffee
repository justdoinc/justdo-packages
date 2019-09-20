_.extend JustdoFiles.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "jdfRemoveFile": (file_id) ->
        check file_id, String

        self.removeFile(file_id, @userId)

        return

    return