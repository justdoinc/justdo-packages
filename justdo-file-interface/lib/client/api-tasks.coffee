_.extend JustdoFileInterface.prototype,
  subscribeToTaskFiles: (task_id, callbacks) ->
    # IMPORTANT! Before calling any tasks methods, you are expected to call this method to load the relevant data.
    #
    # Subscribes to the task files collection of the file system. The precise collection and subscription
    # is determined by the file system, and you shouldn't interact directly with the collection (as it is
    # internal to the file system).
    #
    # This is a reactive resource that calls Meteor.subscribe internally.
    # As such, if this method is called inside an autorun, the subscription will be stopped automatically upon invalidation of the autorun.
    #
    # Receives a task_id and a callbacks object/function, the callbacks object/function is of the exact
    # same format as the callbacks object/function passed to Meteor.subscribe, refer to that API for more details.
    #
    # You are expected to call this method to load the relevant data
    # before calling query-involved methods like `getTaskFileLink`, `getTaskFilesByIds`, `downloadTaskFile`, `showTaskFilePreviewOrStartDownload` and alike.

    return @subscribeToBucketFolder "tasks", task_id, callbacks

  getTaskFileLink: (task_id, file_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    fs = @_getFs()

    return fs.getTaskFileLink task_id, file_id
  
  getTaskFilesByIds: (file_ids, task_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    # 
    # Important: This method return file objects with mostly metadata fields. The field names are normalized to be consistent across file systems.
    # This is meant to facilitate usecases like showing a list of files.
    # Since the field names are normalized, it is discouraged to use this method in other file system methods
    fs = @_getFs()

    if _.isString(file_ids)
      file_ids = [file_ids]
    
    files = fs.getTaskFilesByIds file_ids, task_id

    return files

  isUserAllowedToUploadTaskFile: (task_id, user_id) ->
    fs = @_getFs()

    return fs.isUserAllowedToUploadTaskFile task_id, user_id

  uploadTaskFile: (task_id, file, cb) ->
    fs = @_getFs()

    file_size_limit = @getFileSizeLimit fs.fs_id
    if file_size_limit? and file.size > file_size_limit
      cb @_error "file-size-exceeded", "File size exceeds the #{JustdoHelpers.bytesToHumanReadable file_size_limit} limit of file system #{fs.fs_id}"
      return

    fs.uploadTaskFile task_id, file, cb

    return

  
  downloadTaskFile: (task_id, file_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    fs = @_getFs()

    return fs.downloadTaskFile task_id, file_id

  showTaskFilePreviewOrStartDownload: (task_id, file, file_ids_to_show) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    fs = @_getFs()

    return fs.showTaskFilePreviewOrStartDownload task_id, file, file_ids_to_show
