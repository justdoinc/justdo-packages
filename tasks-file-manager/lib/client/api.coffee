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

  uploadFiles: (task_id, files, cb) ->
    @getUploadPolicy task_id, (error, policy) =>
      if error
        cb error
        return

      if not policy
        cb "get golicy failed."
        return

      upload_options =
        signature: policy.signature
        policy: policy.policy

      _.extend upload_options, @getStorageLocationAndPath(task_id)

      total_files = files.length
      progresses = []
      uploaded = []

      _.each files, (file, i) =>
        APP.filestack_base.filepicker.store(
          file
        ,
          upload_options
        , (blob) =>
            uploaded.push(blob)

            if uploaded.length == total_files
              @registerUploadedFiles task_id, uploaded, (err) ->
                if err?
                  cb err
                  return

                cb null, uploaded
                return

              return
            
            return
        , (error) =>
            cb error, null
            return
        ,
          (progress) =>
            progresses[i] = progress
            total_progress = (_.reduce progresses, (a, b) => (a || 0) + (b || 0)) / total_files

            return
      )

      return

    return
    

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
