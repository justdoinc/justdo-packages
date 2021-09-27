_.extend JustdoHelpers,
  taskCommonName: (task, ellipsis) ->
    # task:
    #
    # If object: assume user_doc
    # otherwise assume @ is user context
    #
    # Will return an empty string if can't provide a common name.


    if not _.isObject task
      task = @

    return JustdoHelpers.ellipsis("##{task.seqId}: #{task.title or ""}", ellipsis)

  getTaskUrl: (project_id, task_id) ->
    base_link = "#{env.WEB_APP_ROOT_URL}/p/#{project_id}#&t=main"
    base_task_link = "#{base_link}&p=/#{task_id}/"

    return base_task_link