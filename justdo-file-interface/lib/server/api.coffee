_.extend JustdoFilesInterface.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  uploadFile: (fs_id, task_id, file_blob, filename, mimetype, metadata, user_id) ->
    fs = @_getFs fs_id

    return await fs.uploadFile task_id, file_blob, filename, mimetype, metadata, user_id
