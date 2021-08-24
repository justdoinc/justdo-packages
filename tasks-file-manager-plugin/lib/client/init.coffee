_.extend TasksFileManagerPlugin.prototype,
  _immediateInit: ->
    APP.hash_requests_handler.addRequestHandler "download-file", (opts) =>
      project_id = opts["project-id"]

      project_subscription = APP.projects.requireProjectTasksSubscription(project_id)

      APP.projects.awaitProjectFirstDdpSyncReadyMsg project_id, =>
        Tracker.nonreactive =>
          Tracker.autorun (c) =>
            complete = ->
              project_subscription.stop()
              c.stop()

              return

            if project_subscription.ready()
              @filestackReadyDfd.done =>
                task_id = opts["task-id"]
                file_id = opts["file-id"]

                @tasks_file_manager.downloadFile task_id, file_id, (err) =>
                  if err?
                    @logger.error err
              
            return
          return
        return
      return
    return

  _deferredInit: ->
    @registerTaskPaneSection()

    return
