_.extend JustdoFiles.prototype,
  removeFile: (file_id, cb) ->
    Meteor.call "jdfRemoveFile", file_id, cb

    return
  
  renameFile: (file_id, new_filename, cb) ->
    Meteor.call "jdfRenameFile", file_id, new_filename, cb
    return

  removeOldAvatars: (options, cb) ->
    if _.isFunction options
      cb = options
      
    Meteor.call "jdfRemoveOldAvatars", options, cb
    return
