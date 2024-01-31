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

  _generateReqForOpenAiTemplateGeneration: (msg) ->
    req = 
        "model": "gpt-4-turbo-preview",
        "messages": [
          {
            "role": "system",
            "content": """
              You are a template generator for a project management software named "JustDo". Your job is to generate relevant tasks template based on user's input in JSON format.  

              Your output of tasks tree should only be in the following structure:
              ###output begin###
              {
                t: <title, a summary of what the user wants to do with JustDo>,
                ts: (tasks) [title(Follow the user's language), start_date, end_date, due_date, state, key(unique sequence id, starting from 0.), subtasks(an array of "output" array, could be omitted if there is no subtasks)] 
              }
              ###output ends###

              In JustDo, parent tasks' date fields will be automatically derived from the child tasks' dates.
              E.g. The earliest child task's start_date will be the parent task's start_date, the latest child task's end_date will be the parent task's end_date.
              Because of this, there is no need to set the dates for parent tasks.
              Note that you will still have to set the dates for child tasks.
              Structure the dates in a way that matches the execution order of tasks inside a project.
              All dates field should be an integer offset relative to today's date or an empty string.
              Use 0 (today's date) as the earliest task start_date.

              Below are all the possible values of the state field:
              possible_states = ["pending", "in-progress", "done", "will-not-do", "on-hold", "duplicate", "nil"]
              All the possible_states, except "will-not-do" and "nil", represents the task state by itself. 
              "nil" is the default state for a task that means there is no state.
              "will-not-do"  means the task is cancelled.
              Apply as many states to the tasks generated as you can, but ensure they make sense (e.g. if a child task is pending/in-progress, the parent task should never be set to done.)
              When generating tasks, use the index of possible_states to reference a state.

              The user's input is how the user intent to use JustDo to manage their team or business. 

              The tree structure should be as follows:
              First layer (root task): The category of the child tasks, or a department.
              Second layer: The projects under the category or the department.
              Third layer: One to three tasks representing action items that can be assigned to team members under the parent category

              Some examples will be provided in the chat history. Use them as a reference to generate the tasks tree structure. 
              Generate 40 to 100 tasks in total.

              Respond only with the generated output array without any spaces, indents or line breaks.
            """
          },
          {
            "role": "user",
            "content": "管理醫院人事部門"
          },
          {
            "role": "assistant",
            "content": "{\"t\":\"人事部門\",\"ts\":[\"醫院人事部門\",0,19,19,6,0,[[\"招聘計劃\",1,5,5,0,1,[[\"醫生招聘\",1,3,3,0,2,[[\"撰寫醫生職位描述\",1,1,1,0,3],[\"發布職位廣告\",2,2,2,0,4],[\"篩選簡歷\",3,3,3,0,5]]],[\"護士招聘\",1,4,4,0,6,[[\"撰寫護士職位描述\",1,1,1,0,7],[\"發布職位廣告\",2,2,2,0,8],[\"篩選簡歷\",3,3,3,0,9],[\"安排面試\",4,4,4,0,10]]],[\"行政人員招聘\",2,5,5,0,11,[[\"撰寫行政人員職位描述\",2,2,2,0,12],[\"發布職位廣告\",3,3,3,0,13],[\"篩選簡歷\",4,4,4,0,14],[\"安排面試\",5,5,5,0,15]]]]],[\"在職培訓\",6,10,10,0,16,[[\"醫生專業培訓\",6,7,7,0,17,[[\"培訓需求分析\",6,6,6,0,18],[\"培訓資料準備\",7,7,7,0,19]]],[\"護士技能培訓\",8,9,9,0,20,[[\"培訓需求分析\",8,8,8,0,21],[\"培訓資料準備\",9,9,9,0,22]]],[\"行政流程培訓\",10,10,10,0,23,[[\"培訓需求分析\",10,10,10,0,24],[\"培訓資料準備\",10,10,10,0,25]]]]],[\"員工績效評估\",11,15,15,0,26,[[\"醫生績效評估\",11,12,12,0,27,[[\"評估標準制定\",11,11,11,0,28],[\"進行績效評估\",12,12,12,0,29]]],[\"護士績效評估\",13,14,14,0,30,[[\"評估標準制定\",13,13,13,0,31],[\"進行績效評估\",14,14,14,0,32]]],[\"行政人員績效評估\",14,15,15,0,33,[[\"評估標準制定\",14,14,14,0,34],[\"進行績效評估\",15,15,15,0,35]]]]],[\"員工健康與福利\",16,19,19,0,36,[[\"健康保險計劃更新\",16,17,17,0,37,[[\"市場調研\",16,16,16,0,38],[\"計劃選擇\",17,17,17,0,39]]],[\"員工支持計劃\",18,19,19,0,40,[[\"心理健康支持\",18,18,18,0,41],[\"運動與健身計劃\",19,19,19,0,42]]]]]]]}"
          },
          {
            "role": "user",
            "content": "Manage a fast food chain"
          },
          {
            "role": "assistant",
            "content": "{\"t\":\"Fast Food Chain\",\"ts\":[\"Manage a Fast Food Chain\",0,99,99,6,0,[[\"Location Management\",1,40,40,0,1,[[\"New Store Openings\",1,10,10,0,2,[[\"Site Selection\",1,2,2,0,3],[\"Lease Negotiations\",3,5,5,0,4],[\"Store Design\",6,7,7,0,5],[\"Construction\",8,10,10,0,6]]],[\"Existing Store Upgrades\",11,20,20,0,7,[[\"Renovation Planning\",11,13,13,0,8],[\"Equipment Upgrades\",14,16,16,0,9],[\"Rebranding\",17,18,18,0,10],[\"Reopening\",19,20,20,0,11]]],[\"Store Closures\",21,30,30,0,12,[[\"Performance Review\",21,22,22,0,13],[\"Asset Liquidation\",23,25,25,0,14],[\"Lease Termination\",26,28,28,0,15],[\"Staff Relocation\",29,30,30,0,16]]],[\"Maintenance\",31,40,40,0,17,[[\"Scheduled Maintenance\",31,34,34,0,18],[\"Emergency Repairs\",35,36,36,0,19],[\"Health and Safety Inspections\",37,38,38,0,20],[\"Equipment Servicing\",39,40,40,0,21]]]]],[\"Operations\",41,70,70,0,22,[[\"Staffing\",41,50,50,0,23,[[\"Recruitment\",41,42,42,0,24],[\"Training\",43,45,45,0,25],[\"Scheduling\",46,48,48,0,26],[\"Performance Management\",49,50,50,0,27]]],[\"Supply Chain Management\",51,60,60,0,28,[[\"Vendor Selection\",51,52,52,0,29],[\"Inventory Management\",53,55,55,0,30],[\"Order Fulfillment\",56,58,58,0,31],[\"Logistics\",59,60,60,0,32]]],[\"Quality Assurance\",61,70,70,0,33,[[\"Food Safety\",61,63,63,0,34],[\"Customer Service Standards\",64,66,66,0,35],[\"Compliance Audits\",67,68,68,0,36],[\"Continuous Improvement\",69,70,70,0,37]]]]],[\"Marketing and Sales\",71,99,99,0,38,[[\"Promotions\",71,80,80,0,39,[[\"Seasonal Campaigns\",71,73,73,0,40],[\"New Product Launches\",74,76,76,0,41],[\"Discount Programs\",77,78,78,0,42],[\"Loyalty Rewards\",79,80,80,0,43]]],[\"Digital Marketing\",81,90,90,0,44,[[\"Social Media\",81,83,83,0,45],[\"Email Campaigns\",84,86,86,0,46],[\"Online Ads\",87,88,88,0,47],[\"Website Updates\",89,90,90,0,48]]],[\"Sales Analysis\",91,99,99,0,49,[[\"Market Trends\",91,93,93,0,50],[\"Sales Reporting\",94,96,96,0,51],[\"Customer Feedback\",97,98,98,0,52],[\"Strategic Adjustments\",99,99,99,0,53]]]]]]]}"
          },
          {
            "role": "user",
            "content": msg
          }
      ],
      "temperature": 1,
      "top_p": 1,
      "n": 1,
      "stream": false,
      "max_tokens": 4096,
      "presence_penalty": 0,
      "frequency_penalty": 0,
      "response_format": {
          "type": "json_object"
      }
    return req
  
  generateTemplateFromOpenAi: (msg) ->
    req = @_generateReqForOpenAiTemplateGeneration msg
    return APP.justdo_ai_kit.openai.createChatCompletion req

  _createSubtreeFromOpenAiOptionsSchema: new SimpleSchema
    project_id:
      type: String
      optional: false
    msg:
      type: String
      optional: false
    set_project_title:
      type: Boolean
      optional: true
      defaultValue: false
  createSubtreeFromOpenAi: (options, user_id) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_createSubtreeFromOpenAiOptionsSchema,
        options or {},
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    if user_id?
      APP.projects.requireUserIsMemberOfProject options.project_id, user_id

    res = @generateTemplateFromOpenAi options.msg

    content = JSON.parse(res.content).choices[0].message.content
    return @_createSubtreeFromOpenAi content, options, user_id

  # The reason for having createSubtreeFromOpenAi and _createSubtreeFromOpenAi as seperate functions
  # is to allow developers to test the generated output from OpenAI API.
  _createSubtreeFromOpenAi: (content, options, user_id) ->
    if _.isString content
      content = JSON.parse content

    if options.set_project_title
      project_title = content.t
      APP.collections.Projects.update options.project_id, {$set: {title: project_title}}

    template = @parseOpenAiTemplateToTasksTemplate content.ts
    create_template_options = 
      project_id: options.project_id
      users: 
        performing_user: user_id
      perform_as: "performing_user"
      template: template
    
    return @createSubtreeFromTemplateUnsafe create_template_options

  parseOpenAiTemplateToTasksTemplate: (tasks_arr) ->
    check tasks_arr, Array

    length = tasks_arr.length
    if (length isnt 7) and (length isnt 8)
      throw @_error "invalid-argument", "Invalid template"

    states = ["pending", "in-progress", "done", "will-not-do", "on-hold", "duplicate", "nil"]
    templateParser = (template_arr) ->
      task_template_obj = {}

      [
        title
        start_date_offset
        end_date_offset
        due_date_offset
        state_idx
        key
        subtasks
      ] = template_arr

      task_template_obj =
        title: title
        start_date: if _.isNumber(start_date_offset) then moment().add(start_date_offset, 'days').format("YYYY-MM-DD") else null
        end_date: if _.isNumber(end_date_offset) then moment().add(end_date_offset, 'days').format("YYYY-MM-DD") else null
        due_date: if _.isNumber(due_date_offset) then moment().add(due_date_offset, 'days').format("YYYY-MM-DD") else null
        state: if (state_idx >= 0) then states[state_idx] else "nil"
        key: key
      
      if subtasks?
        task_template_obj.tasks = []
        for subtask_template_arr in subtasks
          task_template_obj.tasks.push(templateParser(subtask_template_arr, {}))
      
      return task_template_obj
    
    return templateParser tasks_arr
  
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
