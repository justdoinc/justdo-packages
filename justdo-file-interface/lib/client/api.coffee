_.extend JustdoFileInterface.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  uploadTaskFile: (fs_id, file, task_id, cb) ->
    fs = @_getFs fs_id

    await fs.uploadTaskFile file, task_id, cb

    return

  subscribeToTaskFilesCollection: (fs_id, options, cb) ->
    fs = @_getFs fs_id

    return fs.subscribeToTaskFilesCollection options, cb
  
  downloadTaskFile: (fs_id, options) ->
    fs = @_getFs fs_id

    return fs.downloadTaskFile options

  showTaskFilePreviewOrStartDownload: (fs_id, task_id, file, file_ids_to_show) ->
    fs = @_getFs fs_id

    return fs.showTaskFilePreviewOrStartDownload task_id, file, file_ids_to_show