_.extend PACK.modules.due_lists,
  initClient: ->
    return

  _sortGridSectionQueriesOutput: (section_manager, due_list_tasks) ->
    # note: sort sorts in-place
    due_list_tasks.sort (task_a, task_b) ->
      # Note: The only thing fetched for task is its id
      task_a = section_manager.grid_data?.items_by_id?[task_a._id]
      task_b = section_manager.grid_data?.items_by_id?[task_b._id]

      if not task_a? and not task_b?
        return 0

      if not task_a? 
        return 1 # show b first

      if not task_b?
        return -1 # show a first

      # task_a_priority = if task_a.priority? then task_a.priority else 0
      # task_b_priority = if task_b.priority? then task_b.priority else 0

      task_a_priority = task_a.priority or 0
      task_b_priority = task_b.priority or 0

      if task_a_priority != task_b_priority
        if task_a_priority < task_b_priority
          # b has higher priority, show first
          return 1
        else
          return -1

      # Same priority, find minimum date
      getMinString = (strings_array) ->
        result = _.filter(strings_array, (s) -> s?).sort()

        if result.length == 0
          return null

        return result[0]

      task_a_min_date = getMinString([task_a.follow_up, task_a.due_date])
      task_b_min_date = getMinString([task_b.follow_up, task_b.due_date])

      if not task_a_min_date? and not task_b_min_date?
        return 0

      if not task_a_min_date?
        # b has data, a doesn't show b first
        return 1

      if not task_b_min_date?
        return -1

      if task_a_min_date < task_b_min_date
        # a has earlier date, show first
        return -1
      else if task_a_min_date > task_b_min_date
        return 1
      else
        return 0

    return

  gridSectionDueListQuery: (section_manager, conf) ->
    {query, query_options} = @getDueListQuery(conf)

    _.extend query_options,
      # Section managers requires only the _id, item data reactivity
      # is managed by the grid
      fields: {_id: 1}
      # We sort by priority, due_date, follow_up here, because
      # we want the query cursor to trigger reactivity
      # when they cahnge.
      # The actual alogorithm taking care of sorting is
      # _sortDueListTasks().
      sort: {priority: -1, due_date: 1, follow_up: 1}

    if conf.include_my_private_follow_ups
      _.extend query_options,
        sort: {priority: -1, due_date: 1, follow_up: 1, "priv:follow_up"}

    due_list_tasks = APP.collections.Tasks.find(
      query,
      query_options
    ).fetch()

    @_sortGridSectionQueriesOutput(section_manager, due_list_tasks)

    return due_list_tasks

  gridSectionStartDateQuery: (section_manager, conf) ->
    {query, query_options} = @getStartDateQuery(conf)

    _.extend query_options,
      # Section managers requires only the _id, item data reactivity
      # is managed by the grid
      fields: {_id: 1}

      sort: {priority: -1}

    due_list_tasks = APP.collections.Tasks.find(
      query,
      query_options
    ).fetch()

    return due_list_tasks

  gridSectionPrioritizedItemsQuery: (section_manager, conf) ->
    {query, query_options} = @getPrioritizedItemsQuery(conf)

    _.extend query_options,
      # Section managers requires only the _id, item data reactivity
      # is managed by the grid
      fields: {_id: 1}
      sort: {priority: -1}

    due_list_tasks = APP.collections.Tasks.find(
      query,
      query_options
    ).fetch()

    return due_list_tasks

  gridSectionAllInProgressItemsQuery: (section_manager, conf) ->
    {query, query_options} = @getAllInProgressItemsQuery(conf)

    _.extend query_options,
      # Section managers requires only the _id, item data reactivity
      # is managed by the grid
      fields: {_id: 1}
      sort: {priority: -1}

    due_list_tasks = APP.collections.Tasks.find(
      query,
      query_options
    ).fetch()

    return due_list_tasks