# MCP API Server Implementation
# Exposes REST endpoints for MCP clients to interact with JustDo

# import {checkNpmVersions} from "meteor/tmeasday:check-npm-versions"

# checkNpmVersions(
#   "body-parser": "1.20.3"
# , "justdoinc:justdo-mcp")

# bodyParser = Npm.require("body-parser")

_.extend JustdoMcp.prototype,
  _immediateInit: ->
    @_setupConnectHandlers()

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

  # ============================================================================
  # Authentication
  # ============================================================================
  
  # Authenticate a request using Bearer token (Meteor login token)
  # Returns the user object if authenticated, null otherwise
  authenticateRequest: (req) ->
    # Try Bearer token from Authorization header first
    auth_header = req.headers?.authorization
    if auth_header? and auth_header.startsWith("Bearer ")
      token = auth_header.substring(7)
      if not _.isEmpty(token)
        hashed_token = Accounts._hashLoginToken(token)
        user = Meteor.users.findOne(
          {"services.resume.loginTokens.hashedToken": hashed_token},
          {fields: {_id: 1, emails: 1, profile: 1}}
        )
        if user?
          return user

    # Try API Key from X-API-Key header
    api_key = req.headers?["x-api-key"]
    if api_key? and not _.isEmpty(api_key)
      # For now, treat API key as a login token
      # In the future, we can have a separate API keys collection
      hashed_token = Accounts._hashLoginToken(api_key)
      user = Meteor.users.findOne(
        {"services.resume.loginTokens.hashedToken": hashed_token},
        {fields: {_id: 1, emails: 1, profile: 1}}
      )
      if user?
        return user

    # Fallback to cookie-based auth (for browser testing)
    user = JustdoHelpers.getUserObjFromMeteorLoginTokenCookie(req, {fields: {_id: 1, emails: 1, profile: 1}})
    if user?
      return user

    return null

  # ============================================================================
  # HTTP Response Helpers
  # ============================================================================

  sendJsonResponse: (res, status_code, data) ->
    res.statusCode = status_code
    res.setHeader("Content-Type", "application/json")
    res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate")
    res.end(JSON.stringify(data))

    return

  sendErrorResponse: (res, status_code, error_code, message, details) ->
    error_response =
      error:
        code: error_code
        message: message
    if details?
      error_response.error.details = details
    
    @sendJsonResponse(res, status_code, error_response)

    return

  # ============================================================================
  # HTTP Handlers Setup
  # ============================================================================

  _setupConnectHandlers: ->
    self = @
    base_path = @api_base_path

    # -------------------------------------------------------------------------
    # GET /api/mcp/v1/info - Server information
    # -------------------------------------------------------------------------
    WebApp.rawConnectHandlers.use "#{base_path}/info", (req, res, next) =>
      if req.method isnt "GET"
        next()
        return

      @sendJsonResponse res, 200,
        name: "JustDo MCP Server"
        version: JustdoMcp.api_version
        mcp_protocol_version: JustdoMcp.mcp_protocol_version
        capabilities:
          tools: true
          resources: false
          prompts: false

      return

    # -------------------------------------------------------------------------
    # POST /api/mcp/v1/tools/list - MCP-compliant tools list
    # -------------------------------------------------------------------------
    WebApp.rawConnectHandlers.use "#{base_path}/tools/list", (req, res, next) =>
      if req.method isnt "POST" and req.method isnt "GET"
        next()
        return

      Meteor.bindEnvironment(=>
        user = @authenticateRequest(req)
        if not user?
          @sendErrorResponse(res, 401, "unauthorized", "Authentication required")
          return

        tools = @getAvailableToolsForUser(user._id)
        
        # Format as MCP tools/list response
        mcp_tools = _.map tools, (tool) ->
          mcp_tool =
            name: tool.name
            description: tool.description
            inputSchema: tool.input_schema
          
          return mcp_tool

        @sendJsonResponse res, 200,
          tools: mcp_tools

        return
      )()

      return

    # -------------------------------------------------------------------------
    # POST /api/mcp/v1/tools/call - Execute a tool (MCP-compliant)
    # -------------------------------------------------------------------------
    WebApp.rawConnectHandlers.use "#{base_path}/tools/call", (req, res, next) =>
      if req.method isnt "POST"
        next()
        return

      Meteor.bindEnvironment(=>
        user = @authenticateRequest(req)
        if not user?
          @sendErrorResponse(res, 401, "unauthorized", "Authentication required")
          return

        body = req.body
        if not body?.name?
          @sendErrorResponse(res, 400, "invalid-request", "Missing 'name' field in request body")
          return

        tool_name = body.name
        tool_arguments = body.arguments or {}

        try
          result = @executeTool(tool_name, tool_arguments, user._id)
          
          # Format as MCP tools/call response
          @sendJsonResponse res, 200,
            content: [
              {
                type: "text"
                text: JSON.stringify(result, null, 2)
              }
            ]
            isError: false

        catch error
          error_message = error.message or "Tool execution failed"
          @logger.error "Tool execution failed: #{tool_name}", error

          @sendJsonResponse res, 200,
            content: [
              {
                type: "text"
                text: error_message
              }
            ]
            isError: true

        return
      )()

      return

  # ============================================================================
  # Tool Discovery and Execution
  # ============================================================================

  getAvailableToolsForUser: (user_id) ->
    # Get all tool definitions and filter based on user permissions
    all_tools = JustdoMcp.tool_definitions
    available_tools = []

    for tool_name, tool_def of all_tools
      # Check if tool has a required permission
      if tool_def.required_permission?
        # If we have the permissions package, check permission
        if APP.justdo_permissions?
          # For tools that don't require a specific task/justdo context,
          # we just check if the user is logged in
          # More specific permission checks happen during tool execution
          available_tools.push(tool_def)
        else
          # No permissions package, allow all tools
          available_tools.push(tool_def)
      else
        # No permission required, tool is available
        available_tools.push(tool_def)

    return available_tools

  executeTool: (tool_name, input, user_id) ->
    check tool_name, String
    check user_id, String

    tool_def = JustdoMcp.tool_definitions[tool_name]
    if not tool_def?
      throw @_error "tool-not-found", "Tool '#{tool_name}' not found"

    # Execute the tool based on its name
    switch tool_name
      when "list_justdos"
        return @_toolListJustdos(input, user_id)
      when "get_justdo"
        return @_toolGetJustdo(input, user_id)
      when "list_tasks"
        return @_toolListTasks(input, user_id)
      when "get_task"
        return @_toolGetTask(input, user_id)
      # when "create_task"
      #   return @_toolCreateTask(input, user_id)
      # when "update_task"
      #   return @_toolUpdateTask(input, user_id)
      when "get_current_user"
        return @_toolGetCurrentUser(input, user_id)
      # when "list_justdo_members"
      #   return @_toolListJustdoMembers(input, user_id)
      else
        throw @_error "tool-not-found", "Tool '#{tool_name}' is defined but not implemented"

  # ============================================================================
  # Tool Implementations
  # ============================================================================

  _toolListJustdos: (input, user_id) ->
    # List all JustDos (projects) the user is a member of
    query =
      "members.user_id": user_id

    projects = @projects_collection.find(query, {
      fields:
        title: 1
        created_at: 1
    }).fetch()
    
    return {justdos: projects}

  _toolGetJustdo: (input, user_id) ->
    check input.justdo_id, String

    justdo_id = input.justdo_id

    return APP.projects.getProjectIfUserIsMember(justdo_id, user_id)

  _toolListTasks: (input, user_id) ->
    check input.justdo_id, String

    justdo_id = input.justdo_id
    limit = input.limit or 50
    if limit > 200
      limit = 200  # Cap at 200 to prevent performance issues

    # Verify user has access to this JustDo
    project = APP.projects.getProjectIfUserIsMember(justdo_id, user_id)

    query =
      project_id: justdo_id
      users: user_id

    if input.owner_id?
      query.owner_id = input.owner_id

    if input.state?
      query.state = input.state

    tasks = @tasks_collection.find(query, {
      fields:
        _id: 1
        title: 1
        state: 1
        owner_id: 1
        due_date: 1
        priority: 1
        created_at: 1
        seqId: 1
      limit: limit
      sort:
        created_at: -1
    }).fetch()

    return {tasks: tasks}

  _toolGetTask: (input, user_id) ->
    check input.task_id, String

    task_id = input.task_id

    # Find task and verify access
    task = @tasks_collection.findOne(
      {_id: task_id, users: user_id},
      {fields: {
        _id: 1
        title: 1
        state: 1
        owner_id: 1
        due_date: 1
        priority: 1
        created_at: 1
        seqId: 1
        project_id: 1
        parents: 1
        description: 1
        follow_up: 1
        start_date: 1
      }}
    )

    if not task?
      throw @_error "not-found", "Task not found or you don't have access"

    return task

  # _toolCreateTask: (input, user_id) ->
  #   check input.justdo_id, String
  #   check input.title, String

  #   justdo_id = input.justdo_id
    
  #   # Verify user has access to this JustDo
  #   project = @projects_collection.findOne(
  #     {_id: justdo_id, "members.user_id": user_id},
  #     {fields: {_id: 1}}
  #   )

  #   if not project?
  #     throw @_error "not-found", "JustDo not found or you don't have access"

  #   # Check permission if permissions package is available
  #   if APP.justdo_permissions?
  #     APP.justdo_permissions.requireJustdoPermissions("task.add-task", justdo_id, user_id)

  #   # Build task fields
  #   task_fields =
  #     title: input.title
  #     project_id: justdo_id
  #     users: [user_id]
  #     state: "nil"

  #   if input.owner_id?
  #     task_fields.owner_id = input.owner_id

  #   if input.due_date?
  #     task_fields.due_date = new Date(input.due_date)

  #   if input.priority?
  #     task_fields.priority = input.priority

  #   # Determine parent
  #   parent_id = input.parent_id or "0"  # "0" is the root

  #   # Use GridDataCom to add the task
  #   grid_data_com = APP.projects._grid_data_com
  #   task_id = grid_data_com.addChild(parent_id, task_fields, user_id)

  #   if not task_id?
  #     throw @_error "tool-execution-failed", "Failed to create task"

  #   result =
  #     success: true
  #     task_id: task_id
  #     message: "Task created successfully"
  #   return result

  # _toolUpdateTask: (input, user_id) ->
  #   check input.task_id, String

  #   task_id = input.task_id

  #   # Find task and verify access
  #   task = @tasks_collection.findOne(
  #     {_id: task_id, users: user_id},
  #     {fields: {_id: 1, project_id: 1}}
  #   )

  #   if not task?
  #     throw @_error "not-found", "Task not found or you don't have access"

  #   # Build update
  #   update_fields = {}

  #   if input.title?
  #     update_fields.title = input.title

  #   if input.state?
  #     update_fields.state = input.state

  #   if input.owner_id?
  #     update_fields.owner_id = input.owner_id

  #   if input.due_date?
  #     update_fields.due_date = new Date(input.due_date)

  #   if input.priority?
  #     update_fields.priority = input.priority

  #   if _.isEmpty(update_fields)
  #     throw @_error "invalid-tool-input", "No fields to update"

  #   # Use GridDataCom to update
  #   grid_data_com = APP.projects._grid_data_com
  #   grid_data_com.bulkUpdate([{_id: task_id}], {$set: update_fields}, user_id)

  #   result =
  #     success: true
  #     task_id: task_id
  #     message: "Task updated successfully"
  #   return result

  _toolGetCurrentUser: (input, user_id) ->
    return APP.accounts.getUserById user_id

  # _toolListJustdoMembers: (input, user_id) ->
  #   check input.justdo_id, String

  #   justdo_id = input.justdo_id

  #   # Verify user has access to this JustDo
  #   project = @projects_collection.findOne(
  #     {_id: justdo_id, "members.user_id": user_id},
  #     {fields: {_id: 1, members: 1}}
  #   )

  #   if not project?
  #     throw @_error "not-found", "JustDo not found or you don't have access"

  #   # Get user details for all members
  #   member_user_ids = _.pluck(project.members, "user_id")
    
  #   users = Meteor.users.find(
  #     {_id: {$in: member_user_ids}},
  #     {fields: {_id: 1, emails: 1, profile: 1}}
  #   ).fetch()

  #   users_by_id = {}
  #   for user in users
  #     users_by_id[user._id] = user

  #   members = _.map project.members, (member) ->
  #     user = users_by_id[member.user_id]
  #     primary_email = null
  #     if user? and user.emails? and user.emails.length > 0
  #       primary_email = user.emails[0].address

  #     first_name = null
  #     last_name = null
  #     if user? and user.profile?
  #       first_name = user.profile.first_name
  #       last_name = user.profile.last_name

  #     member_result =
  #       user_id: member.user_id
  #       email: primary_email
  #       first_name: first_name
  #       last_name: last_name
  #       is_admin: member.is_admin or false
  #     return member_result

  #   result =
  #     justdo_id: justdo_id
  #     members: members
  #   return result
