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
    fs = @_getFs fs_id

    return fs.getTaskFileLink file_id, task_id
  
  getTaskFilesByIds: (fs_id, file_ids, task_id) ->
    # Important: This method return file objects with mostly metadata fields. The field names are normalized to be consistent across file systems.
    # This is meant to facilitate usecases like showing a list of files.
    # Since the field names are normalized, it is discouraged to use this method in other file system methods (e.g. isTaskFileExists)
    fs = @_getFs fs_id

    if _.isString(file_ids)
      file_ids = [file_ids]
    
    files = fs.getTaskFilesByIds file_ids, task_id

    return files

  isTaskFileExists: (fs_id, file_id, task_id) ->
    fs = @_getFs fs_id

    return fs.isTaskFileExists file_id, task_id
  
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

  subscribeToTaskFilesCollection: (fs_id, task_id, cb) ->
    fs = @_getFs fs_id

    return fs.subscribeToTaskFilesCollection task_id, cb
  
  downloadTaskFile: (fs_id, task_id) ->
    fs = @_getFs fs_id

    return fs.downloadTaskFile task_id

  showTaskFilePreviewOrStartDownload: (fs_id, file, task_id, file_ids_to_show) ->
    fs = @_getFs fs_id

    return fs.showTaskFilePreviewOrStartDownload file, task_id, file_ids_to_show
