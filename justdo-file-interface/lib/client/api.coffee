_.extend JustdoFileInterface.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  getFileSizeLimit: (fs_id) ->
    fs = @_getFs fs_id

    limit = fs.getFileSizeLimit()

    if _.isString limit
      limit = parseInt limit, 10

    return limit

  getTaskFileLink: (fs_id, file_id, task_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    fs = @_getFs fs_id

    return fs.getTaskFileLink file_id, task_id
  
  getTaskFilesByIds: (fs_id, file_ids, task_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    # 
    # Important: This method return file objects with mostly metadata fields. The field names are normalized to be consistent across file systems.
    # This is meant to facilitate usecases like showing a list of files.
    # Since the field names are normalized, it is discouraged to use this method in other file system methods
    fs = @_getFs fs_id

    if _.isString(file_ids)
      file_ids = [file_ids]
    
    files = fs.getTaskFilesByIds file_ids, task_id

    return files

  isFileTypePreviewable: (fs_id, file_type) ->
    fs = @_getFs fs_id

    return fs.isFileTypePreviewable file_type

  isUserAllowedToUploadTaskFile: (fs_id, task_id, user_id) ->
    fs = @_getFs fs_id

    return fs.isUserAllowedToUploadTaskFile task_id, user_id

  uploadTaskFile: (fs_id, file, task_id, cb) ->
    fs = @_getFs fs_id

    file_size_limit = @getFileSizeLimit fs.fs_id
    if file_size_limit? and file.size > file_size_limit
      cb @_error "file-size-exceeded", "File size exceeds the #{JustdoHelpers.bytesToHumanReadable file_size_limit} limit of file system #{fs.fs_id}"
      return

    fs.uploadTaskFile file, task_id, cb

    return

  subscribeToTaskFiles: (fs_id, task_id, cb) ->
    # You are expected to call this method to load the relevant data
    # before calling query-involved methods like `getTaskFileLink`, `getTaskFilesByIds`, `downloadTaskFile`, `showTaskFilePreviewOrStartDownload` and alike.
    fs = @_getFs fs_id

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
  
  downloadTaskFile: (fs_id, task_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    fs = @_getFs fs_id

    return fs.downloadTaskFile task_id

  showTaskFilePreviewOrStartDownload: (fs_id, file, task_id, file_ids_to_show) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    fs = @_getFs fs_id

    return fs.showTaskFilePreviewOrStartDownload file, task_id, file_ids_to_show
