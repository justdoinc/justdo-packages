_.extend JustDoProjectsTemplates.prototype,
  createSubtreeFromTemplate: (options, perform_as) ->
    check(perform_as, String)
    check(perform_as.length > 0, true)

    options.perform_as = perform_as
    @createSubtreeFromTemplateUnsafe(options)

  createSubtreeFromTemplateUnsafe: (options) ->
    { project_id, template, root_task_id, users, perform_as } = options

    parser = new TemplateParser(template, options, null);
    parser.logger = @logger

    parser.createTasks(template.tasks)
    parser.runEvents()

    return parser.task;

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return

TemplateParser = (template, options, parent) ->
  @logger = parent?.logger ? console
  @users = parent?.users ? options.users ? {}
  @tasks = parent?.tasks ? {}
  @postponed_internal_actions = parent?.postponed_internal_actions ? []
  @events = parent?.events ? []
  @options = options ? {}
  @template = template
  @parent = parent

  return

getFromTemplateOnly = (key) ->
  return @template[key]

getFromTemplateOrParents = (key) ->
  return @template[key] ? @parent?.lookup(key)

getFromOptionsOrParents = (key) ->
  return @options[key] ? @parent?.lookup(key)

_.extend TemplateParser.prototype,
  lookup: (key, arg) ->
    if @["lookup:#{key}"]?
      return @["lookup:#{key}"](key, arg)

    @logger.warn "Using default lookup, this is not recommended, please define a method 'lookup:#{key}' on the TemplateParser.prototype"

    return getFromTemplateOrParents(key)

  "lookup:key": getFromTemplateOnly

  "lookup:title": getFromTemplateOnly

  "lookup:events": getFromTemplateOnly

  "lookup:parents": getFromTemplateOnly

  "lookup:title": getFromTemplateOnly

  "lookup:due_date": getFromTemplateOnly

  "lookup:follow_up": getFromTemplateOnly

  "lookup:sub_tasks": (key) ->
    return @template.sub_tasks ? @template.tasks

  "lookup:users": getFromTemplateOrParents

  "lookup:owner": getFromTemplateOrParents

  "lookup:pending_owner": getFromTemplateOrParents

  "lookup:perform_as": (key, event_perform_as) ->
    parent = @parent
    while parent?
      if parent.options?[key]?
        return parent.options[key]
      parent = parent.parent

    if event_perform_as?
      return event_perform_as

    return getFromTemplateOrParents.call(@, key)

  "lookup:root_task_id": getFromOptionsOrParents

  "lookup:project_id": getFromOptionsOrParents

  "lookup:path": (key) ->
    if @parent?.task_id?
      return "/#{@parent.task_id}/"
    if (root_task_id = @lookup "root_task_id")?
      return  "/#{root_task_id}/"
    return "/"

  user: (key) ->
    return @users[key]

  task: (key) ->
    return @tasks[key]

  createTasks: (tasks) ->
    for task in tasks
      parser = new TemplateParser(task, null, @)
      task = parser.createTask()

  createTask: () ->
    path = @lookup "path"
    user = @user @lookup "perform_as"

    task_props =
      project_id: @lookup "project_id"
      title: @lookup "title"
      due_date: @lookup "due_date"
      follow_up: @lookup "follow_up"

    @task_id = APP.projects._grid_data_com.addChild path, task_props, user

    if (key = @lookup "key")
      @tasks[key] = @task_id

    if (users = @lookup "users")
      @addUsers(users)

    if (owner = @lookup "owner")
      @setOwner(owner)

    if (pending_owner = @lookup "pending_owner")
      @setPendingOwner(pending_owner)

    if (tasks = @lookup "sub_tasks")
      @createTasks(tasks)

    if (parents = @lookup "parents")
      @addParents(parents)

    if (events = @lookup "events")
      @addEvents(events)

  addUsers: (users) ->
    perform_as = @user @lookup "perform_as"
    EventsAPI.addUsers.call(@, @task_id, users, perform_as)

  setOwner: (user) ->
    perform_as = @user @lookup "perform_as"
    EventsAPI.setOwner.call(@, @task_id, user, perform_as)

  setPendingOwner: (user) ->
    perform_as = @user @lookup "perform_as"
    EventsAPI.setPendingOwner.call(@, @task_id, user, perform_as)

  addParents: (parents) ->
    perform_as = @lookup "perform_as"
    @postponed_internal_actions.push
      action: "addParents"
      task_id: @task_id
      perform_as: perform_as
      args: parents

  addEvents: (events) ->
    _.each events, (event) =>
      perform_as = @lookup "perform_as", event.perform_as
      @events.push
        action: event.action
        task_id: @task_id
        perform_as: perform_as
        args: event.args

  runEvents: () ->
    _.each @postponed_internal_actions, (event) =>
      perform_as = @user event.perform_as
      # Warn the user that the action doesn't exist if it doesn't exist,
      # skip the event
      EventsAPI[event.action].call(@, event.task_id, event.args, perform_as)

    _.each @events, (event) =>
      perform_as = @user event.perform_as
      # Warn the user that the action doesn't exist if it doesn't exist,
      # skip the event
      EventsAPI[event.action].call(@, event.task_id, event.args, perform_as)

    return

EventsAPI =
  addUsers: (task_id, users, perform_as) ->
    update =
      $addToSet:
        users:
          $each: _.map users, (user) => @user user
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setOwner: (task_id, user, perform_as) ->
    update =
      $set:
        owner_id: @user user
        pending_owner_id: null
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setPendingOwner: (task_id, user, perform_as) ->
    update =
      $set:
        pending_owner_id: @user user
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setFollowUp: (task_id, follow_up, perform_as) ->
    update =
      $set:
        follow_up: follow_up
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setDueDate: (task_id, due_date, perform_as) ->
    update =
      $set:
        due_date: due_date
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setStatus: (task_id, status, perform_as) ->
    update =
      $set:
        status: status
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setState: (task_id, state, perform_as) ->
    update =
      $set:
        state: state
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  addParents: (task_id, parents, perform_as) ->
    for parent in parents
      update =
        parent: @task parent

      APP.projects._grid_data_com.addParent task_id, update, perform_as

  removeParents: (task_id, parents, perform_as) ->
    for parent in parents
      APP.projects._grid_data_com.removeParent "/#{@task parent}/#{task_id}/", perform_as
