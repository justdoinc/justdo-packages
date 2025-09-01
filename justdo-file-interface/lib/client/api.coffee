_.extend JustdoFilesInterface.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  uploadFile: (fs_id, file, options, cb) ->
    fs = @_getFs fs_id

    await fs.uploadFile file, options, cb

    return

  subscribeToFilesCollection: (fs_id, options, cb) ->
    fs = @_getFs fs_id

    return fs.subscribeToFilesCollection options, cb
  
  downloadFile: (fs_id, options) ->
    fs = @_getFs fs_id

    return fs.downloadFile options

  showPreviewOrStartDownload: (fs_id, task_id, file, file_ids_to_show) ->
    fs = @_getFs fs_id

    return fs.showPreviewOrStartDownload task_id, file, file_ids_to_show