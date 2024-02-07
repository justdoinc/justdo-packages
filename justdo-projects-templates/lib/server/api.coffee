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

  _generateStreamReq: (msg) ->
    req = 
      "model": "gpt-3.5-turbo-0125",
      "messages": [
        {
          "role": "system",
          "content": """
            Based on user input, generate an array of tasks. They must be relevant to the user input.

            Below is the JSON schema of a task object:
            ### JSON schema begin ###
            {
              "type": "object",
              "properties": {
                "title": {
                  "type": "string",
                  "description": "Title of the task describing the task, or describing what the child tasks does if it has child tasks."
                },
                "start_date_offset": {
                  "type": "number",
                  "description": "Start date of the task represented by the offset in days relative to today's date"
                },
                "end_date_offset": {
                  "type": "number",
                  "description": "End date of the task represented by the offset in days relative to today's date"
                },
                "due_date_offset": {
                  "type": "number",
                  "description": "Due date of the task represented by the offset in days relative to today's date"
                },
                "state_idx": {
                  "type": "number",
                  "description": "Index of the task's state from this list: ['pending', 'in-progress', 'done', 'will-not-do', 'on-hold', 'duplicate', 'nil']"
                },
                "key": {
                  "type": "number",
                  "description": "0-based sequence ID of the task."
                },
                "parent_task_key": {
                  "type": "number",
                  "description": "Parent task's key. The parent task must exist before referencing. If the task is a top-level task, use -1."
                }
              }
            }
            ### JSON schema ends ###

            The tasks hierachy are as follows:
            ### Tasks hierarchy begin ###
            Top level tasks must have 3 to 6 child tasks, and it's depth must be 3 to 5 levels.

            Depth means the number of levels of the task tree. E.g. a top-level task with no child tasks has a depth of 1, a top-level task with 1 child task has a depth of 2, and so on.

            The title of top level tasks must be a category or a department.

            Immediate child tasks of top level tasks must be projects under the category or the department.

            Other child tasks must be action items that can be assigned to team members under the parent project or category.

            All child tasks must be grouped under a relevant parent task.
            ### Tasks hierarchy ends ###

            Only set dates for child tasks. For parent tasks, set the date to an empty string.

            For state_idx field:
            "nil" is the default state for a task that means there is no state.
            "will-not-do"  means the task is cancelled.
            Apply as many states to the tasks generated as you can, but ensure they make sense (e.g. if a child task is pending/in-progress, the parent task should never be set to done.)
            When generating tasks, use the index of possible_states to reference a state.

            To reduce the size of task definition, use an array to represent a task. The array must contain only the value of the task object, in the order of the schema.
            Generate 45 to 60 tasks in total. Return only the array without any formatting like whitespaces and line breakes.
          """.trim()
        },
        {
          "role": "user",
          "content": "Manage a tech startup"
        },
        {
          "role": "assistant",
          "content": """[["Product Development", "", "", "", 6, 0, -1], ["Website Launch", "", "", "", 6, 1, 0], ["Design Homepage", 1, 7, 7, 2, 2, 1], ["Setup Hosting", 0, 1, 1, 1, 3, 1], ["Implement SEO Best Practices", 3, 10, 10, 0, 4, 1], ["Launch Marketing Campaign", 8, 14, 14, 2, 5, 1], ["App Development", "", "", "", 6, 6, 0], ["Design UI/UX", 1, 14, 14, 1, 7, 6], ["Develop Backend", 3, 30, 40, 1, 8, 6], ["Quality Assurance", 15, 50, 50, 1, 9, 6], ["Publish to App Store", 51, 60, 60, 0, 10, 6], ["Market Research", "", "", "", 6, 11, 0], ["Identify Target Market", 0, 5, 5, 1, 12, 11], ["Competitor Analysis", 1, 10, 10, 1, 13, 11], ["Product Feedback Loop", 11, 60, 60, 1, 14, 11], ["Sales Strategy", "", "", "", 6, 15, 0], ["Define Pricing Model", 3, 7, 7, 1, 16, 15], ["Identify Sales Channels", 4, 8, 8, 1, 17, 15], ["Train Sales Team", 5, 9, 9, 1, 18, 15], ["Operate Sales Campaigns", 10, 60, 60, 0, 19, 15], ["Customer Support Setup", "", "", "", 6, 20, 0], ["Implement Support Software", 2, 9, 9, 1, 21, 20], ["Hire Support Team", 3, 12, 12, 1, 22, 20], ["Train Support Team", 13, 20, 20, 1, 23, 20], ["Publish FAQ and Documentation", 10, 15, 15, 1, 24, 20], ["Investor Relations", "", "", "", 6, 25, 0], ["Prepare Investment Deck", 5, 12, 12, 1, 26, 25], ["Identify Potential Investors", 1, 5, 5, 1, 27, 25], ["Schedule Meetings", 6, 18, 18, 1, 28, 25], ["Follow-up Communications", 19, 22, 22, 1, 29, 25], ["Legal & Compliance", "", "", "", 6, 30, 0], ["Register Business", 0, 1, 1, 1, 31, 30], ["Trademark Product Names", 2, 8, 8, 1, 32, 30], ["Legal Review of Contracts", 3, 9, 9, 1, 33, 30], ["Ensure Data Protection Compliance", 4, 10, 10, 1, 34, 30], ["Financial Planning", "", "", "", 6, 35, 0], ["Budget Allocation", 1, 3, 3, 1, 36, 35], ["Cash Flow Management", 2, 6, 6, 1, 37, 35], ["Financial Reporting", 4, 8, 8, 1, 38, 35], ["Resource Planning", "", "", "", 6, 39, 0], ["Hire Key Roles", 1, 7, 7, 1, 40, 39], ["Allocate Office Space", 2, 8, 8, 1, 41, 39], ["Setup Workstations", 3, 9, 9, 1, 42, 39], ["Technology Procurement", 4, 10, 10, 1, 43, 39], ["Team Development", "", "", "", 6, 44, 0], ["Regular Team Meetings", 1, 30, 30, 1, 45, 44], ["Team Building Activities", 10, 40, 40, 0, 46, 44], ["Professional Development Programs", 15, 45, 45, 1, 47, 44], ["Performance Review Process", 20, 50, 50, 1, 48, 44]]"""
        }
        {
          "role": "user",
          "content": msg.trim()
        }
      ],
      "temperature": 1,
      "top_p": 1,
      "n": 1,
      "stream": true,
      "max_tokens": 4096,
      "presence_penalty": 0,
      "frequency_penalty": 0,
    return req

  streamTemplateFromOpenAi: (msg, user_id) ->
    req = @_generateStreamReq msg
    request_id = await APP.justdo_ai_kit.openai.createChatCompletion req, user_id
    stream = await APP.justdo_ai_kit.openai.getRequest request_id

    
    await return stream
  
  streamTemplateFromOpenAiMethodHandler: (msg, user_id) ->
    check msg, String
    check user_id, String

    self = @

    pub_id = Random.id()
    Meteor.publish pub_id, ->
      publish_this = @
      stream = await self.streamTemplateFromOpenAi msg, user_id
      
      self.once "stop_stream_#{pub_id}_#{user_id}", ->
        stream.abort()
        publish_this.stop()
        return

      tasks = []
      task_string = ""
      task_key_to_created_id = {}
      _parseStreamedTasks = (task_arr) ->
        states = ["pending", "in-progress", "done", "will-not-do", "on-hold", "duplicate", "nil"]
        grid_data = APP.projects._grid_data_com
        
        [
          title
          start_date_offset
          end_date_offset
          due_date_offset
          state_idx
          key
          parent_task_key
        ] = task_arr

        fields = 
          _id: key
          pub_id: pub_id
          parent: parent_task_key
          title: title
          start_date: if _.isNumber(start_date_offset) then moment().add(start_date_offset, 'days').format("YYYY-MM-DD") else null
          end_date: if _.isNumber(end_date_offset) then moment().add(end_date_offset, 'days').format("YYYY-MM-DD") else null
          due_date: if _.isNumber(due_date_offset) then moment().add(due_date_offset, 'days').format("YYYY-MM-DD") else null
          state: if (state_idx >= 0) then states[state_idx] else "nil"

        return fields

      for await part from stream
        res += part.choices[0].delta.content
        task_string += part.choices[0].delta.content

        if task_string.includes "]"
          # Replace double brackets with single brackets
          task_string = task_string.replace /\[\s*\[/g, "["
          task_string = task_string.replace /\]\s*\]/g, "]"

          # When the task_string contains a complete task, parse it and add it to the tasks array
          [finished_task_string, incomplete_task_string] = task_string.split(/],?/)

          # Add back the missing bracket from .split()
          finished_task_string += "]"

          task_arr = JSON.parse finished_task_string
          task = _parseStreamedTasks task_arr
          @added "ai_response", task._id, task
          task_string = incomplete_task_string
      
      stream.done().then ->
        publish_this.stop()
        self.off "stop_stream_#{pub_id}_#{user_id}"
        return

      return
    
    return pub_id
    

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
