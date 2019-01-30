_.extend TasksFileManager.prototype,
  makeDropPane: (task_id) ->
    return new TasksFileManager.DropPane task_id, @

  downloadFile: (task_id, file_id, cb) ->
    @getDownloadLink task_id, file_id, (err, url) ->
      if err then cb(err)
      else
        # cause the browser to download this url rather than open it,
        # which prevents the file from being displayed in place of the
        # current page and also avoids triggering pop-up blockers.
        # Source: https://www.filestack.com/docs/file-ingestion/rest-api/retrieving
        url += "&dl=true"

        # opens the url in the current tab, which won't actually open it
        # in the current tab because of the &dl=true which sets the
        # appropriate headers indicating that the browser should download
        # the file instead.
        window.location.href = url

        cb()

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
