_.extend JustDoProjectsTemplates.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    # Defined below
    @_registerAIRequestTemplates()

    return

  createSubtreeFromTemplateUnsafe: (options) ->
    for role, user_id of options.users
      if not APP.accounts.getUserById(user_id)?
        throw @_error "unknown-user", "User #{role} does not exist"

    parser = new TemplateParser(options.template, options, null)
    parser.logger = @logger

    parser.createTasks(options.template.tasks)
    parser.runEvents()

    @emit "post-create-subtree-from-template", options

    return {paths_to_expand: parser.paths_to_expand, first_root_task_id: parser.tasks?.first_root_task}

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
  
  _registerAIRequestTemplates: ->
    if not APP.justdo_ai_kit?
      return
    
    for template_id, req_template_def of JustDoProjectsTemplates.ai_requests
      options = _.extend {template_id: template_id}, req_template_def
      APP.justdo_ai_kit.registerRequestTemplate options
    
    return

  _generateProjectTitleReq: (msg) ->
    req = 
      "model": JustDoProjectsTemplates.openai_template_generation_model,
      "messages": [
        {
          "role": "system",
          "content": """
            You are a project title generator.
            Summerize user input to a few words that will be used in a project's title. 
            Treat the word "JustDo" in any user input as the same meaning as project, and do not include them in the response..
            Ensure to follow user's input language when generating response.
          """
        },
        {
          "role" : "user",
          "content" : "I'd like to manage a corner store"
        },
        {
          "role" : "assistant",
          "content" : "Corner store management"
        },
        {
          "role" : "user",
          "content" : "管理醫院"
        },
        {
          "role" : "assistant",
          "content" : "醫院管理"
        },
        {
          "role" : "user",
          "content" : "為科技公司建立JustDo"
        },
        {
          "role" : "assistant",
          "content" : "科技公司"
        },
        {
          "role" : "user",
          "content" : "I'd like to manage a tech company that has about 10 employees"
        },
        {
          "role" : "assistant",
          "content" : "Tech startup management"
        },
        {
          "role" : "user",
          "content" : "科技公司"
        },
        {
          "role" : "assistant",
          "content" : "科技公司"
        },
        {
          "role" : "user",
          "content" : "Create a project for an IT company"
        },
        {
          "role" : "assistant",
          "content" : "IT Firm"
        },
        {
          "role" : "user",
          "content" : "Create project for Real Estate company"
        },
        {
          "role" : "assistant",
          "content" : "Home Builders Inc."
        },
        {
          "role" : "user",
          "content" : "Create project for Movie Production company"
        },
        {
          "role" : "assistant",
          "content" : "Movie Production"
        },
        {
          "role" : "user",
          "content" : "診所"
        },
        {
          "role" : "assistant",
          "content" : "醫療診所"
        },
        {
          "role" : "user",
          "content" : "ניהול מקלט לבעלי חיים"
        },
        {
          "role" : "assistant",
          "content" : "מקלט לבעלי חיים"
        },
        {
          "role": "user",
          "content": msg.trim()
        }
      ],
      "temperature": 1,
      "top_p": 1,
      "n": 1,
      "max_tokens": 128,
      "presence_penalty": 0,
      "frequency_penalty": 0,
    return req
  
  generateProjectTitleFromOpenAiMethodHandler: (msg, user_id) ->
    check msg, String
    check user_id, String

    req = @_generateProjectTitleReq msg
    res = await APP.justdo_ai_kit.openai.createChatCompletion req, user_id

    await return res?.choices?[0]?.message?.content

getFromTemplateOnly = (key) ->
  return @template[key]

getFromTemplateOrParents = (key) ->
  return @template[key] ? @parent?.lookup(key)

getFromOptionsOrParents = (key) ->
  return @options[key] ? @parent?.lookup(key)

TemplateParser = (template, options, parent) ->
  @logger = parent?.logger ? console
  @users = parent?.users ? options.users ? {}
  @tasks = parent?.tasks ? {}
  @postponed_internal_actions = parent?.postponed_internal_actions ? []
  @events = parent?.events ? []
  @options = options ? {}
  @template = template
  @parent = parent
  if not parent?
    @paths_to_expand = []

  return

_.extend TemplateParser.prototype,
  lookup: (key, arg) ->
    if @["lookup:#{key}"]?
      return @["lookup:#{key}"](key, arg)

    @logger.warn "Using default lookup, this is not recommended, please define a method 'lookup:#{key}' on the TemplateParser.prototype"

    return getFromTemplateOrParents(key)

  "lookup:key": getFromTemplateOnly

  "lookup:dep_id": getFromTemplateOnly

  "lookup:title": ->
    if (i18n_title = @template.title_i18n)?
      user_id = @users.performing_user
      if _.isFunction i18n_title
        return i18n_title user_id
      if _.isObject i18n_title
        return APP.justdo_i18n.tr i18n_title.key, i18n_title.options, user_id
      return APP.justdo_i18n.tr i18n_title, {}, user_id

    return @template.title

  "lookup:events": getFromTemplateOnly

  "lookup:parents": getFromTemplateOnly

  "lookup:state": getFromTemplateOnly

  "lookup:start_date": getFromTemplateOnly

  "lookup:end_date": getFromTemplateOnly

  "lookup:due_date": getFromTemplateOnly

  "lookup:follow_up": getFromTemplateOnly

  "lookup:expand": getFromTemplateOnly

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

  "lookup:status_i18n": ->
    if not (status_i18n = getFromTemplateOnly.call(@, "status_i18n"))?
      return

    perform_as = @user @lookup "perform_as"

    if _.isObject status_i18n
      status = APP.justdo_i18n.tr status_i18n.key, status_i18n.options, perform_as
    if _.isString status_i18n
      status = APP.justdo_i18n.tr status_i18n, {}, perform_as
    return status
  
  "lookup:archived": ->
    if getFromTemplateOnly.call(@, "archived")
      return new Date()
    return null

  "lookup:path": (key) ->
    if @parent?.task_id? and @parent?.task_id isnt "/"
      return "/#{@parent.task_id}/"
    if (root_task_id = @lookup "root_task_id")? and root_task_id isnt "/"
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

    return

  createTask: ->
    path = @lookup "path"
    user = @user @lookup "perform_as"

    task_props =
      project_id: @lookup "project_id"
      title: @lookup "title"
      start_date: @lookup "start_date"
      end_date: @lookup "end_date"
      due_date: @lookup "due_date"
      follow_up: @lookup "follow_up"
      state: @lookup "state"
      archived: @lookup "archived"
    
    if (status = @lookup "status_i18n")?
      task_props.status = status

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

    if (expand = @lookup "expand")
      @setExpand()

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

  runEvents: ->
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

  setExpand: ->
    task_ids = [@task_id]
    parent = @parent

    # Traverse up the tree of TemplateParser objects, until we get to the root
    while parent?.task_id?
      task_ids.push parent.task_id
      parent = parent.parent

    path_to_expand = GridData.helpers.joinPathArray task_ids.reverse()
    # Add expanded paths to the root TemplateParser
    parent.paths_to_expand.push path_to_expand
    return

EventsAPI =
  addUsers: (task_id, users, perform_as) ->
    update =
      $set:
        users: _.map users, (user) => @user user
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setOwner: (task_id, user, perform_as) ->
    update =
      $set:
        owner_id: @user user
        pending_owner_id: null
        is_removed_owner: null
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

  setStatus: (task_id, status_i18n, perform_as) ->
    if _.isObject status_i18n
      status = APP.justdo_i18n.tr status_i18n.key, status_i18n.options, perform_as
    else
      status = APP.justdo_i18n.tr status_i18n, {}, perform_as
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

  setArchived: (task_id, args, perform_as) ->
    update =
      $set:
        archived: new Date()
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  unsetArchived: (task_id, args, perform_as) ->
    update =
      $set:
        archived: null
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  toggleIsProject: (task_id, args, perform_as) ->
    APP.justdo_delivery_planner.toggleTaskIsProject task_id, perform_as

  update: (task_id, update, perform_as) ->
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  # deps: (An arrey of dep_id OR object that has the same structure as items inside justdo_task_dependencies_mf)
  #   dep_id: (String) key as defined in template obj
  #   type: (String) Supported dependency type (default is F2S), optional
  #   lag: (Number) Lag in days, optional
  addGanttDependency: (task_id, deps, perform_as) ->
    if _.isString deps
      deps = [deps]
    if _.isEmpty deps
      return
    
    deps = _.map deps, (dep) => 
      if _.isString dep
        dep_id = dep
      else
        dep_id = dep.dep_id
      dep_task_id = @tasks[dep_id]
      dep_obj = {task_id: dep_task_id, type: deps.type or "F2S", lag: deps.lag or 0}
      return dep_obj

    update = 
      $set:
        "#{JustdoPlanningUtilities.dependencies_mf_field_id}": deps
    
    APP.projects._grid_data_com.updateItem task_id, update, perform_as
