_.extend JustdoFileInterface.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  getFileSizeLimit: (fs_id) ->
    fs = @_getFs()

    limit = fs.getFileSizeLimit()

    if _.isString limit
      limit = parseInt limit, 10

    return limit

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

  isFileTypePreviewable: (file_type) ->
    fs = @_getFs()

    return fs.isFileTypePreviewable file_type

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

  subscribeToTaskFiles: (task_id, callbacks, fs_id) ->
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
    # fs_id is optional, if not provided, the current default file system will be used.
    #
    # You are expected to call this method to load the relevant data
    # before calling query-involved methods like `getTaskFileLink`, `getTaskFilesByIds`, `downloadTaskFile`, `showTaskFilePreviewOrStartDownload` and alike.
    fs = @_getFs()

    # Note: If cb is passed to the subscribeToTaskFiles directly,
    # it's treated as the onReady callback, and the onStop callback is ignored.
    # As such, the cb will not be called with the error if the subscription fails.
    # So we need to use a sub_options object instead.
    is_on_ready_cb_called = false
    sub_options = 
      onReady: ->
        is_on_ready_cb_called = true
        cb?()
        return
      onStop: (err) ->
        if not is_on_ready_cb_called
          cb? err
        return

    return fs.subscribeToTaskFiles task_id, sub_options
  
  downloadTaskFile: (task_id, file_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    fs = @_getFs()

    return fs.downloadTaskFile task_id, file_id

  showTaskFilePreviewOrStartDownload: (task_id, file, file_ids_to_show) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    fs = @_getFs()

    return fs.showTaskFilePreviewOrStartDownload task_id, file, file_ids_to_show
