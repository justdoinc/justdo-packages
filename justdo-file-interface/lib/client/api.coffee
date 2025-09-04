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

  subscribeToTaskFilesCollection: (fs_id, task_id, cb) ->
    fs = @_getFs fs_id

    return fs.subscribeToTaskFilesCollection task_id, cb
  
  downloadTaskFile: (fs_id, task_id) ->
    fs = @_getFs fs_id

    return fs.downloadTaskFile task_id

  showTaskFilePreviewOrStartDownload: (fs_id, file, task_id, file_ids_to_show) ->
    fs = @_getFs fs_id

    return fs.showTaskFilePreviewOrStartDownload file, task_id, file_ids_to_show