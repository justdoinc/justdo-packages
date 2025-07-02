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

  subscribeToFilesCollection: (fs_id, options) ->
    fs = @_getFs fs_id

    await fs.subscribeToFilesCollection options

    return
  
  downloadFile: (fs_id, options) ->
    fs = @_getFs fs_id

    await fs.downloadFile options

    return