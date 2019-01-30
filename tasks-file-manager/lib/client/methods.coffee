_.extend TasksFileManager.prototype,

  getUploadPolicy: (task_id, cb) ->
    Meteor.call('tfm_GetUploadPolicy', task_id, cb)

  # XXX XXX Security hole here:
  # A user who optains a valid file url can fake the files argument here
  # and upload that url to their own task.
  # Several possible solutions:
  # 1. Check that the file has not been uploaded before.
  # 2. Require the client to submit the upload policy and check the path against
  #    the task_id
  # 3. (Not a valid fix.) Don't expose the file url to the user. One problem
  #    with this approach is that we must expose the url for downloading,
  #    making it possible (though unlikely) for the url to be exposed to non-
  #    authorized users (e.g. in logs of downloaded files).
  registerUploadedFiles: (task_id, files, cb) ->
    Meteor.call('tfm_RegisterUploadedFiles', task_id, files, cb)

  getDownloadLink: (task_id, file_id, cb) ->
    Meteor.call('tfm_GetDownloadLink', task_id, file_id, cb)

  renameFile: (task_id, file_id, newTitle, cb) ->
    Meteor.call('tfm_RenameFile', task_id, file_id, newTitle, cb)

  removeFile: (task_id, file_id, cb) ->
    Meteor.call('tfm_RemoveFile', task_id, file_id, cb)
