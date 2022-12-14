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

  getCoreState: (state) ->
    if not state?
      return null

    prefix_idx = state.indexOf("::")
    if prefix_idx == -1
      return state
    return state.substring(0, prefix_idx)
  
  isCoreStateMongoQuery: (core_state) ->
    return {
      $regex: "^#{core_state}"
    }

  getCoreStateMongoQuery: (core_state, options) ->
    options = _.extend {
      $ne: false
    }, options
    query = @isCoreStateMongoQuery(core_state)
    if options.$ne
      query = {$not: query}
    return {
      state: query
    }
  
  getCoreStateMongoQueries: (core_states, options) ->
    return core_states.map((core_state) => @getCoreStateMongoQuery(core_state, options))
