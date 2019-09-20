_.extend JustdoFiles.prototype,
  removeFile: (file_id, cb) ->
    Meteor.call "jdfRemoveFile", file_id, cb

    return