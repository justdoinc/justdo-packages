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
  
  isStateOneOfCoreStatesRegex: (core_states) ->
    if _.isEmpty(core_states)
      throw new Error("No core states provided")

    if _.isString(core_states) and not _.isArray(core_states)
      return "^#{core_state}"

    check core_states, [String]

    return "^(#{core_states.join("|")})"
  
  getCoreStateOneOfCoreStatesQuery: (core_states) -> {$regex: isStateOneOfCoreStateRegex(core_states)}

  getCoreStateNotOneOfCoreStatesQuery: (core_states) -> {$regex: {$not: isStateOneOfCoreStateRegex(core_states)}}
