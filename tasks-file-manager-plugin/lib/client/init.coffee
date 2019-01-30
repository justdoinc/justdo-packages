_.extend TasksFileManagerPlugin.prototype,
  _immediateInit: ->
    APP.hash_requests_handler.addRequestHandler "download-file", (opts) =>
      @filestackReadyDfd.done =>
        task_id = opts["task-id"]
        file_id = opts["file-id"]

        @tasks_file_manager.downloadFile task_id, file_id, (err) =>
          if err?
            @logger.error err

      return
    return

  _deferredInit: ->
    @registerTaskPaneSection()

    return
