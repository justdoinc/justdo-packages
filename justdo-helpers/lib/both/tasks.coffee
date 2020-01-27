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
