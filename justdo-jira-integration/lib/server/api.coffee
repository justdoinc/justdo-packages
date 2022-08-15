{URL, URLSearchParams} = JustdoHelpers.url
root = exports ? @
root.URL = -> URL
{Version2Client, AgileClient} = Npm.require "jira.js"
crypto = Npm.require "crypto"
OAuth = Npm.require "oauth-1.0a"

_.extend JustdoJiraIntegration.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    @setupJiraRoutes()

    @_setupJiraClientForAllJustdosWithRefreshToken()
    # XXX This setInterval ensures the oauth login remain valid after its 1 hour lifespan, runs every 1 hour.
    # XXX Currently for demo only and will be integrated with db-migration package.
    Meteor.setInterval =>
      @_setupJiraClientForAllJustdosWithRefreshToken()
    , 3600000

    @_setupInvertedFieldMap()

    @clients = {}

    @deleted_issue_keys = new Set()

    # XXX if oauth1 in use
    @oauth_token_to_justdo_id = {}

    return

  performInstallProcedures: (project_doc, user_id) ->
    # Called when plugin installed for project project_doc._id
    # console.log "Plugin #{JustdoJiraIntegration.project_custom_feature_id} installed on project #{project_doc._id}"

    return

  performUninstallProcedures: (project_doc, user_id) ->
    # Called when plugin uninstalled from project project_doc._id

    # Note, isn't called on project removal

    # console.log "Plugin #{JustdoJiraIntegration.project_custom_feature_id} removed from project #{project_doc._id}"

    return

  isJiraIntegrationInstalledOnJustdo: (justdo_id) ->
    query =
      _id: justdo_id
      "conf.custom_features": "justdo_jira_integration"
    return @projects_collection.findOne(query, {fields: {_id: 1}})?

  _getJustdoAdmin: (justdo_id) ->
    return @projects_collection.findOne({_id: justdo_id, "members.is_admin": true}, {fields: {"members.$.user_id": 1}}).members[0].user_id

  _setupInvertedFieldMap: ->
    JustdoJiraIntegration.jira_field_to_justdo_field_map = {}
    for task_field, issue_field_def of JustdoJiraIntegration.justdo_field_to_jira_field_map
      JustdoJiraIntegration.jira_field_to_justdo_field_map[issue_field_def.name] = task_field
      if issue_field_def.id
        JustdoJiraIntegration.jira_field_to_justdo_field_map[issue_field_def.id] = task_field
    return

  # XXX Think of a better way to handle cases for both issue_created and issue_updated?
  _mapJiraFieldsToJustdoFields: (justdo_id, req_body, options) ->
    if not justdo_id?
      throw @_error "justdo-id-not-found"

    # issue_updated
    if options?.use_changelog
      {changelog} = req_body
      fields_map =
        $set: {}
        $addToSet: {}
        $pull: {}

      for changed_item in changelog.items
        jira_field_name = changed_item.fieldId or changed_item.field
        if not (justdo_field_name = JustdoJiraIntegration.jira_field_to_justdo_field_map[jira_field_name])?
          continue
        jira_field_def = JustdoJiraIntegration.justdo_field_to_jira_field_map[justdo_field_name]
        jira_field_type = jira_field_def.type

        if jira_field_def.mapper?
          field_val = await jira_field_def.mapper.call @, justdo_id, changed_item, "justdo", req_body
        else if jira_field_type is "string"
          field_val = changed_item.toString
        else if jira_field_type is "array"
          {fromString, toString} = changed_item

          # From null to something, assume add/set
          if _.isNull(fromString) and _.isString(toString)
            if not fields_map.$addToSet[justdo_field_name]?
              fields_map.$addToSet[justdo_field_name] =
                $each: []
            fields_map.$addToSet[justdo_field_name].$each.push toString

          # From something to null, assume remove/unset
          if _.isString(fromString) and _.isNull(toString)
            if not fields_map.$pull[justdo_field_name]?
              fields_map.$pull[justdo_field_name] =
                $in: []
            fields_map.$pull[justdo_field_name].$in.push fromString

          continue
        else
          field_val = changed_item.to

        # if (field_map = JustdoJiraIntegration.justdo_field_to_jira_field_map[justdo_field_name].map)?
        #   field_val = _.findKey field_map, (val) -> val is field_val

        fields_map.$set[justdo_field_name] = field_val
    # issue_created
    else
      {fields} = req_body.issue
      fields_map = {}

      for justdo_field_name, jira_field_def of JustdoJiraIntegration.justdo_field_to_jira_field_map
        field_key = jira_field_def.id or jira_field_def.name
        jira_field = fields[field_key]
        if (_.isEmpty jira_field) and not (_.isNumber jira_field) and not (_.isBoolean jira_field)
          continue

        if jira_field_def.mapper?
          field_val = await jira_field_def.mapper.call @, justdo_id, jira_field, "justdo", req_body
        else if _.isString jira_field
          field_val = jira_field
        else if _.isArray jira_field
          fields_map[justdo_field_name] = []
          for sub_field in jira_field
            fields_map[justdo_field_name].push sub_field.name
          continue
        else
          field_val = jira_field.name

        fields_map[justdo_field_name] = field_val

    return fields_map

  _mapJustdoFieldsToJiraFields: (justdo_id, task_doc, modifier) ->
    fields_to_update =
      fields: {}
      transition: {}

    for field_name, field_val of modifier.$set

      if not (jira_field_def = JustdoJiraIntegration.justdo_field_to_jira_field_map[field_name])?
        continue

      jira_field_name = jira_field_def.id or jira_field_def.name

      if jira_field_def.mapper?
        # Some updates require using different APIs.
        # If the mapper doesn't return a value, assume the update are performed inside the mapper.
        if (mapped_field_val = await jira_field_def.mapper.call @, justdo_id, field_val, "jira", task_doc)?
          if field_name is "state"
            fields_to_update.transition =
              id: mapped_field_val
          else
            fields_to_update.fields[jira_field_name] = mapped_field_val
      else if jira_field_def.map?[field_val]?
        fields_to_update.fields[jira_field_name] = jira_field_def.map[field_val]
      else
        fields_to_update.fields[jira_field_name] = field_val

    return fields_to_update

  _createTaskFromJiraIssue: (justdo_id, parent_path, jira_issue_body, options) ->
    # XXX Use schema for checking options?

    jira_issue_key = jira_issue_body.key
    justdo_admin_id = @_getJustdoAdmin justdo_id

    task_fields =
      project_id: justdo_id
      jira_issue_key: jira_issue_key
      jira_last_updated: new Date()

    _.extend task_fields, await @_mapJiraFieldsToJustdoFields justdo_id, {issue: jira_issue_body}

    task_owner_id = task_fields.owner_id or justdo_admin_id

    gc = APP.projects._grid_data_com
    created_task_id = ""
    try
      created_task_id = gc.addChild parent_path, task_fields, task_owner_id
    catch e
      console.log jira_issue_key, parent_path, "failed"

    if task_fields.jira_issue_reporter?
      APP.tasks_changelog_manager.logChange
        field: "jira_issue_reporter"
        label: "Issue Reporter"
        change_type: "custom"
        task_id: created_task_id
        by: task_fields.jira_issue_reporter
        new_value: "became reporter"

    if task_fields.jira_issue_type isnt "Sub-task"
      parent_task = @tasks_collection.findOne GridDataCom.helpers.getPathItemId parent_path, {fields: {jira_sprint: 1, jira_fix_version: 1}}
      if (issue_sprint = task_fields.jira_sprint)? and (issue_sprint isnt parent_task.jira_sprint)
        console.log "-----Adding to sprint-----"
        console.log "Task id:", created_task_id
        console.log "Sprint:", issue_sprint
        console.log "Sprint mountpoints:", options.sprints_mountpoints
        gc.addParent created_task_id, {parent: options.sprints_mountpoints[issue_sprint]}, task_owner_id

      if task_fields.jira_fix_version?
        for fix_version in task_fields.jira_fix_version
          if not _.contains parent_task.jira_fix_version, fix_version
            console.log "-----Adding to fix version-----"
            console.log "Task id:", created_task_id
            console.log "Fix version:", fix_version
            console.log "Fix version mountpoints:", options.fix_versions_mountpoints
            gc.addParent created_task_id, {parent: options.fix_versions_mountpoints[fix_version]}, task_owner_id

    console.log jira_issue_key, "created_task_id", created_task_id
    @setJustdoIdandTaskIdToJiraIssue justdo_id, created_task_id, jira_issue_key
    return created_task_id

  jiraWebhookEventHandlers:
    "jira:issue_created": (req_body) ->
      {fields} = req_body.issue
      # Created from Justdo. Ignore.
      if fields[JustdoJiraIntegration.project_id_custom_field_id] or fields[JustdoJiraIntegration.task_id_custom_field_id]
        return
      jira_issue_key = req_body.issue.key
      jira_project_key = jira_issue_key.split("-")[0]
      if not _.isEmpty (mounted_justdo_and_task = @getJustdosIdsAndTasksIdsfromMountedJiraProjectKey jira_project_key)
        {justdo_id, task_id} = mounted_justdo_and_task

        if not @isJiraIntegrationInstalledOnJustdo justdo_id
          return

        path_to_add = "/#{task_id}/"
        if fields.parent?
          parent_id = @tasks_collection.findOne({jira_issue_key: fields.parent.key}, {fields: {_id: 1}})._id
          path_to_add = "/#{parent_id}/"

        user_ids_to_be_added_to_task = new Set()
        user_ids_to_be_added_to_task.add @_getJustdoAdmin justdo_id
        jira_user_emails = @getAllJiraProjectMembers(jira_project_key).map (user) ->
          user_ids_to_be_added_to_task.add Accounts.findUserByEmail(user.email)?._id
          return user.email
        user_ids_to_be_added_to_task = Array.from user_ids_to_be_added_to_task
        @_createTaskFromJiraIssue justdo_id, path_to_add, req_body.issue, user_ids_to_be_added_to_task

      return
    "jira:issue_updated": (req_body) ->
      # Updates from Justdo. Ignore.
      if _.find req_body.changelog.items, (item) -> item.field is "jd_last_updated"
        return

      {fields} = req_body.issue
      {[JustdoJiraIntegration.task_id_custom_field_id]:task_id, [JustdoJiraIntegration.project_id_custom_field_id]:justdo_id} = fields
      if not task_id?
        task = @tasks_collection.findOne({jira_issue_key: req_body.issue.key}, {fields: {project_id: 1}})
        {_id:task_id, project_id:justdo_id} = task

      if not @isJiraIntegrationInstalledOnJustdo justdo_id
        return

      grid_data = APP.projects._grid_data_com
      jira_project_mountpoint = @getJustdosIdsAndTasksIdsfromMountedJiraProjectKey(fields.project.key).task_id

      if (_.find req_body.changelog.items, (item) -> item.field is "issuetype" and item.toString is "Epic")?
        # Move all child tasks to root level of mounted project
        @tasks_collection.find({"parents2.parent": task_id}, {fields: {_id: 1}}).forEach (child_task) =>
          grid_data.movePath "/#{task_id}/#{child_task._id}/", {parent: jira_project_mountpoint}, @_getJustdoAdmin justdo_id

        # Move the target task that was changed to epic
        parent_task_id = @tasks_collection.findOne(task_id, {fields: {parents2: 1}}).parents2[0].parent
        old_path = "/#{parent_task_id}/#{task_id}/"

        grid_data.movePath old_path, {parent: jira_project_mountpoint}, @_getJustdoAdmin justdo_id

      if (changed_issue_parent = _.find req_body.changelog.items, (item) -> item.field in ["IssueParentAssociation", "Parent Issue"])?
        current_parent_task_id = @tasks_collection.findOne(task_id, {fields: {parents2: 1}}).parents2[0].parent
        old_path = "/#{current_parent_task_id}/#{task_id}/"

        # Change/Add parent
        if (new_parent_issue_id = changed_issue_parent.to)?
          if (parent_issue = fields.parent)?
            new_parent_issue_key = parent_issue.key
            new_parent_task_id = @tasks_collection.findOne({project_id: justdo_id, jira_issue_key: new_parent_issue_key}, {fields: {_id: 1}})._id
          else
            client = @getJiraClientForJustdo(justdo_id)
            new_parent_issue = await client.v2.issues.getIssue({issueIdOrKey: new_parent_issue_id})
            new_parent_task_id = new_parent_issue.fields[JustdoJiraIntegration.task_id_custom_field_id]
          new_parent = {parent: new_parent_task_id}
        # Remove parent
        else
          new_order = @tasks_collection.findOne(current_parent_task_id, {fields: {parents2: 1}})?.parents2?[0]?.order
          new_parent = {parent: jira_project_mountpoint, order: new_order + 1}

        grid_data.movePath old_path, new_parent, @_getJustdoAdmin justdo_id

      if not _.isEmpty ({$set, $addToSet, $pull} = await @_mapJiraFieldsToJustdoFields justdo_id, req_body, {use_changelog: true})
        ops =
          $set:
            updated_by: @_getJustdoAdmin justdo_id
            jira_last_updated: new Date()
        if not _.isEmpty $set
          _.extend ops.$set, $set
        # $addToSet cannot be called with $pull on the same field, thus we execute the $pull operation first
        if not _.isEmpty($addToSet) and not _.isEmpty($pull)
          temp_ops = _.extend {}, ops
          temp_ops.$pull = $pull
          @tasks_collection.update task_id, temp_ops
          $pull = null
        if not _.isEmpty $addToSet
          ops.$addToSet = $addToSet
        if not _.isEmpty $pull
          ops.$pull = $pull
        @tasks_collection.update task_id, ops
        return
    "jira:issue_deleted": (req_body) ->
      # Actually we only need jira issue key/id for deletion, but for consistency we still take req_body as parameter
      {[JustdoJiraIntegration.task_id_custom_field_id]:task_id, [JustdoJiraIntegration.project_id_custom_field_id]:justdo_id} = req_body.issue.fields
      if not @isJiraIntegrationInstalledOnJustdo justdo_id
        return

      # Task deletion from Justdo. Ignore.
      if @deleted_issue_keys.delete req_body.issue.key
        return

      @tasks_collection.remove task_id

      return
    "jira:version_created": (req_body) ->
      fix_version = req_body.version

      # If the Jira project isn't mounted, ignore.
      if not (jira_project_key = @getJiraProjectKeyByIdIfMounted fix_version.projectId)?
        return

      tasks_query =
        jira_project_key: jira_project_key
        jira_mountpoint_type: "fix_versions"
      tasks_options =
        project_id: 1
      if (fix_versions_mountpiont_task_doc = @tasks_collection.findOne tasks_query, tasks_options)?
        task_fields =
          project_id: fix_versions_mountpiont_task_doc.project_id
          title: fix_version.name
          jira_fix_version_mountpoint_id: fix_version.id
          start_date: fix_version.startDate
          due_date: fix_version.releaseDate
        APP.projects._grid_data_com.addChild "/#{fix_versions_mountpiont_task_doc._id}/", task_fields, @_getJustdoAdmin fix_versions_mountpiont_task_doc.project_id

      jira_query =
        "jira_projects.#{jira_project_key}":
          $ne: null
      jira_ops =
        $addToSet:
          "jira_projects.#{jira_project_key}.fix_versions": fix_version
      @jira_collection.update jira_query, jira_ops
      return
    "jira:version_updated": (req_body) ->
      fix_version = req_body.version

      # If the Jira project isn't mounted, ignore.
      if not (jira_project_key = @getJiraProjectKeyByIdIfMounted fix_version.projectId)?
        return

      tasks_query =
        jira_fix_version_mountpoint_id: parseInt fix_version.id
      # XXX This query is to fetch project_id for getting the Justdo admin user id for updated_by in tasks.update()
      justdo_id = @tasks_collection.findOne(tasks_query, {fields: {project_id: 1}}).project_id
      tasks_ops =
        $set:
          title: fix_version.name
          start_date: fix_version.startDate or null
          due_date: fix_version.releaseDate or null
          jira_last_updated: new Date()
          updated_by: @_getJustdoAdmin justdo_id
      @tasks_collection.update tasks_query, tasks_ops

      jira_query =
        "mounted_projects.#{jira_project_key}.fix_versions.id": fix_version.id
      jira_ops =
        $set:
          "mounted_projects.#{jira_project_key}.fix_versions.$": fix_version
      @jira_collection.update jira_query, jira_ops

      return
    "sprint_created": (req_body) ->
      sprint = req_body.sprint
      jira_host = new URL(sprint.self).origin
      client = @getClientByHost(jira_host).agile

      board_id = sprint.originBoardId
      @getAllAssociatedJiraProjectsByBoardId(board_id, {client})
        .then (res) =>
          query =
            $or: []
          ops =
            $addToSet: {}

          _.each res.values, (jira_project) =>
            jira_project_key = jira_project.key

            tasks_query =
              jira_project_key: jira_project_key
              jira_mountpoint_type: "sprints"
            tasks_options =
              project_id: 1
            if (sprint_mountpiont_task_doc = @tasks_collection.findOne(tasks_query, tasks_options))?
              task_fields =
                project_id: sprint_mountpiont_task_doc.project_id
                title: sprint.name
                jira_sprint_mountpoint_id: sprint.id
                start_date: moment.utc(sprint.startDate).format "YYYY-MM-DD"
                end_date: moment.utc(sprint.startDate).format "YYYY-MM-DD"
              APP.projects._grid_data_com.addChild "/#{sprint_mountpiont_task_doc._id}/", task_fields, @_getJustdoAdmin sprint_mountpiont_task_doc.project_id

            query.$or.push
              "jira_projects.#{jira_project_key}":
                $ne: null
            ops.$addToSet["jira_projects.#{jira_project_key}.sprints"] = sprint

          @jira_collection.update query, ops

          return
        .catch (err) -> console.error err
      return
    "sprint_updated": (req_body) ->
      # TODO: Update sprint name
      {id, name, startDate, endDate, originBoardId} = req_body.sprint

      tasks_query =
        jira_sprint_mountpoint_id: id

      justdo_id = @tasks_collection.findOne(tasks_query, {fields: {project_id: 1}}).project_id
      client = @getJiraClientForJustdo(justdo_id).agile

      jira_query =
        $or: []
      jira_ops =
        $set: {}

      @getJiraProjectsByBoardId originBoardId, {client}
        .then (res) =>
          # Updates task
          tasks_ops =
            $set:
              jira_last_updated: new Date()
              title: name
              start_date: null
              end_date: null
              updated_by: @_getJustdoAdmin justdo_id
          if startDate?
            tasks_ops.$set.start_date = moment.utc(startDate).format "YYYY-MM-DD"
          if endDate?
            tasks_ops.$set.end_date = moment.utc(endDate).format "YYYY-MM-DD"
          @tasks_collection.update tasks_query, tasks_ops, {multi: true}

          # Updates Jira collection
          _.each res.values, (project_info) =>
            jira_query.$or.push
              "jira_projects.#{project_info.key}.sprints.id": id
            _.extend jira_ops.$set,
              "jira_projects.#{project_info.key}.sprints.$.name": name
              "jira_projects.#{project_info.key}.sprints.$.startDate": startDate or null
              "jira_projects.#{project_info.key}.sprints.$.endDate": endDate or null
              "jira_projects.#{project_info.key}.sprints.$.originBoardId": originBoardId

          @jira_collection.update jira_query, jira_ops
          return
        .catch (err) -> console.error err
      return

  getOAuth1LoginLink: (justdo_id, user_id) ->
    if not APP.projects.isProjectAdmin justdo_id, user_id
      throw @_error "permission-denied"

    oauth = new OAuth
      consumer:
        key: @consumer_key
        secret: @private_key
      signature_method: "RSA-SHA1"
      hash_function: (base_string, key) =>
        sign = crypto.createSign "RSA-SHA1"
        sign.update base_string
        result = sign.sign @private_key, "base64"
        return result
    req =
      url: "#{@jira_server_host}/plugins/servlet/oauth/request-token"
      method: "POST"
    req.headers = oauth.toHeader oauth.authorize req

    res = Meteor.wrapAsync(HTTP.post)("#{@jira_server_host}/plugins/servlet/oauth/request-token", req)
    if res?.statusCode isnt 200
      # Error occured
      return res
    res_params = new URLSearchParams res.content
    oauth_token = res_params.get "oauth_token"
    @oauth_token_to_justdo_id[oauth_token] = justdo_id
    return "#{@jira_server_host}/plugins/servlet/oauth/authorize?oauth_token=#{oauth_token}"

  getOAuth2LoginLink: (justdo_id, user_id) ->
    if not APP.projects.isProjectAdmin justdo_id, user_id
      throw @_error "permission-denied"

    base_url = new URL "https://auth.atlassian.com/authorize"

    params = new URLSearchParams
      audience: "api.atlassian.com"
      client_id: @client_id
      redirect_uri: "#{process.env.ROOT_URL}/jira/oAuthCallback"
      scope: "offline_access read:board-scope.admin:jira-software read:project:jira write:sprint:jira-software read:board-scope:jira-software read:issue-details:jira read:sprint:jira-software read:jira-work manage:jira-project manage:jira-configuration read:jira-user write:jira-work manage:jira-webhook manage:jira-data-provider"
      state: justdo_id
      response_type: "code"
      prompt: "consent"

    base_url.search = params

    return base_url

  _getRelevantCustomFieldIdsInJira: (justdo_id, user_id) ->
    client = @getJiraClientForJustdo(justdo_id).v2

    custom_field_query =
      type: "custom"
      query: "jd_"

    # Jira cloud
    if client.config.host.includes "api.atlassian.com"
      jira_custom_fields = await client.issueFields.getFieldsPaginated custom_field_query
    # Jira server
    else
      custom_field_query = new URLSearchParams(custom_field_query).toString()
      HTTP.get "#{client.host}/rest/api/2/customFields?#{custom_field_query}", (err, res) ->
        if err?
          console.error err.response
          return
        console.log res

    return

  _setupJiraClientForAllJustdosWithRefreshToken: ->
    @jira_collection.find({refresh_token: {$exists: true}}, {fields: {server_info: 1}}).forEach (doc) =>
      console.log "Refreshing Jira OAuth2 access token for Jira server #{doc.server_info?.name}"
      @refreshJiraAccessToken doc.server_info?.id
      return

  _parseAndStoreJiraCredentials: (res, options) ->
    if not options.justdo_id? and not options.jira_server_id?
      throw @_error "missing-parameter"

    justdo_id = options.justdo_id
    if res.statusCode is 200
      {access_token, refresh_token} = res.data

      get_accessible_resources_options =
        headers:
          Authorization: "Bearer #{access_token}"
          Accept: "application/json "
      res = await HTTP.get "https://api.atlassian.com/oauth/token/accessible-resources", get_accessible_resources_options

      credentials = {access_token, refresh_token}
      credentials.server_info = res.data?[0]
      query =
        "server_info.id": credentials.server_info.id
      ops =
        $set: credentials
      # justdo_id is provided when a new login toward Jira is performed,
      # and not required during access token refresh upon server restart.
      if justdo_id?
        # Since one Justdo can only log into one jira server at a time, we remove all the previous associations.
        @jira_collection.update {justdo_ids: justdo_id}, {$pull: {justdo_ids: justdo_id}}, {multi: true}

        ops.$addToSet =
          justdo_ids: justdo_id

      @jira_collection.upsert query, ops

      jira_clients_config =
        host: "https://api.atlassian.com/ex/jira/#{res.data[0].id}"
        authentication:
          oauth2:
            accessToken: access_token
      @clients[credentials.server_info.id] =
        v2: new Version2Client jira_clients_config
        agile: new AgileClient jira_clients_config
      client = @clients[credentials.server_info.id]

      # Fetch all fix versions and sprints, then store in db
      justdo_ids_mounted_to_this_jira_server = @jira_collection.findOne("server_info.id": credentials.server_info.id, {fields: {justdo_ids: 1}})?.justdo_ids
      all_mounted_jira_project_keys_set = @getAllMountedJiraProjectKeysAsSetByJustdoIds justdo_ids_mounted_to_this_jira_server

      all_mounted_jira_project_keys_set.forEach (jira_project_key) =>
        @fetchAndStoreAllSprintsUnderJiraProject jira_project_key, _.extend {}, options, {client: client.agile}
        @fetchAndStoreAllFixVersionsUnderJiraProject jira_project_key, _.extend {}, options, {client: client.v2}
        @fetchAndStoreAllUsersUnderJiraProject jira_project_key, _.extend {}, options, {client: client.v2}

      return

  setupJiraRoutes: ->
    self = @
    GET_OAUTH_TOKEN_REQUEST_TEMPLATE =
      headers:
        "Content-Type": "application/json"
      data:
        grant_type: "authorization_code"
        client_id: @client_id
        client_secret: @client_secret
        code: ""
        redirect_uri: "#{process.env.ROOT_URL}/jira/oAuthCallback/"

    # Route for oAuth callback
    Router.route "/jira/oAuthCallback", {where: "server"}
      .get ->
        @response.end()
        # code is used to obtain access_token
        # state is the custom state key we pass. Currently is the justdo_id where we perform the authorization
        {code, state:justdo_id, oauth_token} = @request.query # equiv. justdo_id = state
        # If oauth_token exists, assume OAuth1 toward Jira server is in use
        if oauth_token?
          # XXX Remove when custom field are fetched using API
          JustdoJiraIntegration.task_id_custom_field_id = "customfield_10200"
          JustdoJiraIntegration.project_id_custom_field_id = "customfield_10201"
          JustdoJiraIntegration.last_updated_custom_field_id = "customfield_10202"

          JustdoJiraIntegration.start_date_custom_field_id = "customfield_10101"
          JustdoJiraIntegration.justdo_field_to_jira_field_map.start_date.id = "customfield_10101"
          JustdoJiraIntegration.justdo_field_to_jira_field_map.start_date.name = "Target start"

          JustdoJiraIntegration.end_date_custom_field_id = "customfield_10102"
          JustdoJiraIntegration.justdo_field_to_jira_field_map.end_date.id = "customfield_10102"
          JustdoJiraIntegration.justdo_field_to_jira_field_map.end_date.name = "Target end"

          JustdoJiraIntegration.sprint_custom_field_id = "customfield_10108"
          JustdoJiraIntegration.justdo_field_to_jira_field_map.jira_sprint.id = "customfield_10108"

          justdo_id = self.oauth_token_to_justdo_id[oauth_token]

          oauth = new OAuth
            consumer:
              key: self.consumer_key
              secret: self.private_key
            signature_method: "RSA-SHA1"
            hash_function: (base_string, key) ->
              sign = crypto.createSign "RSA-SHA1"
              sign.update base_string
              result = sign.sign self.private_key, "base64"
              return result

          get_oauth_token_req =
            url: "http://52.11.164.210:8080/plugins/servlet/oauth/access-token"
            method: "POST"

          get_oauth_token_req.headers = oauth.toHeader oauth.authorize get_oauth_token_req, {key: oauth_token}

          HTTP.post get_oauth_token_req.url, get_oauth_token_req, (err, res) ->
            if err?
              console.error err.response
              return
            res_params = new URLSearchParams res.content

            self.jira_collection.update {justdo_id}, {$set: {"server_info.url": "http://52.11.164.210:8080"}}

            jira_clients_config =
              host: self.jira_server_host
              authentication:
                oauth:
                  consumerKey: self.consumer_key
                  consumerSecret: self.private_key
                  accessToken: res_params.get "oauth_token"
                  tokenSecret: res_params.get "oauth_token_secret"
            self.clients[justdo_id] =
              v2: new Version2Client jira_clients_config
              agile: new AgileClient jira_clients_config

        # If code exists, assume OAuth2 toward Jira cloud is in use.
        if code?
          # XXX Remove when custom field are fetched using API

          # XXX For IT only
          # JustdoJiraIntegration.task_id_custom_field_id = "customfield_10035"
          # JustdoJiraIntegration.project_id_custom_field_id = "customfield_10034"
          # JustdoJiraIntegration.last_updated_custom_field_id = "customfield_10033"
          # JustdoJiraIntegration.sprint_custom_field_id = "customfield_10020"
          # JustdoJiraIntegration.justdo_field_to_jira_field_map.jira_sprint.id = "customfield_10020"

          get_oauth_token_req = _.extend {}, GET_OAUTH_TOKEN_REQUEST_TEMPLATE
          get_oauth_token_req.data.code = code
          HTTP.post self.get_oauth_token_endpoint, get_oauth_token_req, (err, res) ->
            if err?
              console.error err.response
              return
            self._parseAndStoreJiraCredentials res, {justdo_id}
            return

    # Route for webhook
    Router.route "/jira/webhook", {where: "server"}
      .post ->
        @response.end()
        event_type = @request.body.webhookEvent
        self.jiraWebhookEventHandlers[event_type]?.call(self, @request.body)
        return

    return

  refreshJiraAccessToken: (jira_server_id) ->
    self = @
    if (refresh_token = @jira_collection.findOne({"server_info.id": jira_server_id}, {fields: {refresh_token: 1}})?.refresh_token)?
      req =
        headers:
          "Content-Type": "application/json"
        data:
          grant_type: "refresh_token"
          refresh_token: refresh_token
          client_id: @client_id
          client_secret: @client_secret
      HTTP.post self.get_oauth_token_endpoint, req, (err, res) =>
        if err?
          console.error err.response
          return
        @_parseAndStoreJiraCredentials res, {jira_server_id}
        return

    return

  mountTaskWithJiraProject: (task_id, jira_project_key, jira_project_id, user_id) ->
    justdo_id = APP.collections.Tasks.findOne(task_id, {fields: {project_id: 1}})?.project_id
    if not @isJiraIntegrationInstalledOnJustdo justdo_id
      throw @_error "not-supported", "Jira integration is not installed on this project: #{justdo_id}"

    if not APP.projects.isProjectAdmin justdo_id, user_id
      throw @_error "permission-denied"

    client = @getJiraClientForJustdo justdo_id

    Promise
      .all [
        # Ensure all project members is either normal or proxy users, and add them as member to the target Justdo.
        @fetchAndStoreAllUsersUnderJiraProject jira_project_key, {justdo_id: justdo_id, client: client.v2}
        # Fetch all sprints and fixed versions under the current Jira project
        @fetchAndStoreAllSprintsUnderJiraProject jira_project_key, {justdo_id: justdo_id, client: client.agile}
        @fetchAndStoreAllFixVersionsUnderJiraProject jira_project_key, {justdo_id: justdo_id, client: client.v2}
      ]
      .then =>
        # Remove previous mountpoint record of the same Jira project, and clear all issue keys in relevant to that mountpoint.
        @unmountAllTasksRelevantToJiraProject jira_project_key, user_id

        justdo_admin_id = @_getJustdoAdmin justdo_id
        # XXX If the Justdo admin is guarenteed to also be a member of the moutned Jira project,
        # XXX change the following to an array and remove default value.
        # Get an array of user_ids of Jira project members to be inserted in tasks created from Jira issue
        user_ids_to_be_added_to_child_tasks = new Set()
        user_ids_to_be_added_to_child_tasks.add justdo_admin_id
        jira_user_emails = @getAllJiraProjectMembers(jira_project_key).map (user) ->
          user_ids_to_be_added_to_child_tasks.add Accounts.findUserByEmail(user.email)?._id
          return user.email
        user_ids_to_be_added_to_child_tasks = Array.from user_ids_to_be_added_to_child_tasks

        # Ensures all Jira project members has access to current Justdo and
        @addJiraProjectMembersToJustdo justdo_id, jira_user_emails

        # Add task members to the mounted task
        @tasks_collection.update task_id, {$set: {jira_project_key: jira_project_key, jira_mountpoint_type: "root"}, $addToSet: {users: {$each: user_ids_to_be_added_to_child_tasks}}}

        # Setup mountpoints for sprints and fix versions
        gc = APP.projects._grid_data_com

        jira_query =
          "jira_projects.#{jira_project_key}":
            $ne: null
        jira_query_options =
          fields:
            "jira_projects.#{jira_project_key}": 1
        jira_project_sprints_and_fix_versions = @jira_collection.findOne(jira_query, jira_query_options)
        jira_project_sprints_and_fix_versions = jira_project_sprints_and_fix_versions?.jira_projects?[jira_project_key]

        # Create the three special task that groups all the sprints and fix versions, and all the tasks
        # roadmap_mountpoint currently holds all the issues
        roadmap_mountpoint_task_id = gc.addChild "/#{task_id}/", {title: "Roadmap", project_id: justdo_id, jira_project_key: jira_project_key, jira_mountpoint_type: "roadmap", jira_last_updated: new Date()}, justdo_admin_id
        # XXX Might need some special treatment for these two tasks and their child
        # XXX Like bolding the title, prevent removal, etc etc
        sprints_mountpoint_task_id = gc.addChild "/#{task_id}/", {title: "Sprints", project_id: justdo_id, jira_project_key: jira_project_key, jira_mountpoint_type: "sprints", jira_last_updated: new Date()}, justdo_admin_id
        fix_versions_mountpoint_task_id = gc.addChild "/#{task_id}/", {title: "Fix Versions", project_id: justdo_id, jira_project_key: jira_project_key, jira_mountpoint_type: "fix_versions", jira_last_updated: new Date()}, justdo_admin_id
        # Since the row style data cannot be inserted along addChild, we perform the update here.
        @tasks_collection.update {_id: {$in: [roadmap_mountpoint_task_id, sprints_mountpoint_task_id, fix_versions_mountpoint_task_id]}}, {$set: {"jrs:style": {bold: true}}}, {multi: true}

        # Create all the sprints and fix versions as task that groups all the issues under the same attribute
        sprints_to_mountpoint_task_id = {}
        if jira_project_sprints_and_fix_versions.sprints?
          for sprint in jira_project_sprints_and_fix_versions.sprints
            task_fields =
              project_id: justdo_id
              title: sprint.name
              jira_sprint_mountpoint_id: sprint.id
              jira_last_updated: new Date()
            if sprint.startDate?
              task_fields.start_date = moment(sprint.startDate).format("YYYY-MM-DD")
            if sprint.endDate?
              task_fields.end_date = moment(sprint.endDate).format("YYYY-MM-DD")
            sprints_to_mountpoint_task_id[sprint.name] = gc.addChild "/#{sprints_mountpoint_task_id}/", task_fields, justdo_admin_id

        fix_versions_to_mountpoint_task_id = {}
        if jira_project_sprints_and_fix_versions.fix_versions
          for fix_version in jira_project_sprints_and_fix_versions.fix_versions
            task_fields =
              project_id: justdo_id
              title: fix_version.name
              jira_fix_version_mountpoint_id: fix_version.id
              jira_last_updated: new Date()
            if fix_version.start_date?
              task_fields.start_date = moment(fix_version.startDate).format("YYYY-MM-DD")
            if fix_version.due_date?
              task_fields.due_date = moment(fix_version.releaseDate).format("YYYY-MM-DD")
            fix_versions_to_mountpoint_task_id[fix_version.name] = gc.addChild "/#{fix_versions_mountpoint_task_id}/", task_fields, justdo_admin_id

        # Create new mountpoint record in projects collection
        ops =
          $addToSet:
            "justdo_jira_integration.mounted_tasks":
              task_id: roadmap_mountpoint_task_id
              jira_project_key: jira_project_key
              jira_project_id: jira_project_id
        @projects_collection.update justdo_id, ops

        # Search for all issues under the Jira project and create tasks in Justdo
        # issueSearch has searchForIssuesUsingJql() and searchForIssuesUsingJqlPost()
        # Both works the same way except the latter one uses POST to support a larger query
        # For consistency with future development, only searchForIssuesUsingJqlPost() is used.
        issue_search_body =
          jql: "project=#{jira_project_key} order by issuetype asc"
          maxResults: 300
          fields: @getAllRelevantJiraFieldIds()
        client.v2.issueSearch.searchForIssuesUsingJqlPost issue_search_body
          .then (res) =>
            {issues} = res
            while (issue = issues.shift())?
              issue_fields = issue.fields
              parent_key = null
              path_to_add = "/#{task_id}/#{roadmap_mountpoint_task_id}/"

              if (parent = issue_fields.parent)? or (parent_key = issue_fields[JustdoJiraIntegration.epic_link_custom_field_id])?
                if not parent_key?
                  parent_key = parent.key
                # XXX Hardcoded users length in query. Better approach is needed to determine whether the parent task is added completely along with its users.
                # if not (parent_task_id = @tasks_collection.findOne({project_id: justdo_id, jira_issue_key: parent_key}, {fields: {_id: 1}})?._id)?
                if not (parent_task_id = @tasks_collection.findOne({project_id: justdo_id, jira_issue_key: parent_key, "users.1": {$exists: true}}, {fields: {_id: 1}})?._id)?
                  issues.push issue
                  continue
                path_to_add = "/#{parent_task_id}/"
              create_task_from_jira_issue_options =
                sprints_mountpoints: sprints_to_mountpoint_task_id
                fix_versions_mountpoints: fix_versions_to_mountpoint_task_id
              @_createTaskFromJiraIssue justdo_id, path_to_add, issue, create_task_from_jira_issue_options
          .catch (err) -> console.error err
      .catch (err) -> console.error err

    return

  # Unmounts a single task/Jira project pair
  unmountTaskWithJiraProject: (justdo_id, jira_project_key, user_id) ->
    if not @isJiraIntegrationInstalledOnJustdo justdo_id
      throw @_error "not-supported", "Jira integration is not installed on this project: #{justdo_id}"

    if not APP.projects.isProjectAdmin justdo_id, user_id
      throw @_error "permission-denied"

    all_sprints_and_fix_versions_under_jira_project = @getAllStoredSprintsAndFixVersionsByJiraProjectKey jira_project_key
    all_sprint_ids_under_jira_project = _.map all_sprints_and_fix_versions_under_jira_project.sprints, (sprint) -> sprint.id
    all_fix_version_ids_under_jira_project = _.map all_sprints_and_fix_versions_under_jira_project.fix_versions, (fix_version) -> fix_version.id

    # Remove issue keys under this Jira Project under this Justdo
    tasks_query =
      project_id: justdo_id
      $or: [
        jira_project_key: jira_project_key
      ,
        jira_issue_key:
          $regex: "#{jira_project_key}-\\d"
          $options: "i"
      ,
        jira_sprint_mountpoint_id:
          $in: all_sprint_ids_under_jira_project
      ,
        jira_fix_version_mountpoint_id:
          $in: all_fix_version_ids_under_jira_project
      ]
    tasks_ops =
      $set:
        updated_by: user_id
        jira_project_key: null
        jira_issue_key: null
        jira_mountpoint_type: null
        jira_sprint_mountpoint_id: null
        jira_fix_version_mountpoint_id: null
    @tasks_collection.update tasks_query, tasks_ops, {multi: true}

    # Remove mountpoint record in projects collection
    justdo_ops =
      $pull:
        "justdo_jira_integration.mounted_tasks":
          jira_project_key: jira_project_key
    @projects_collection.update justdo_id, justdo_ops

    jira_query =
      justdo_ids: justdo_id
      "jira_projects.#{jira_project_key}":
        $ne: null
    jira_ops =
      $unset:
        "jira_projects.#{jira_project_key}": 1
    @jira_collection.update jira_query, jira_ops

    return

  # Unmounts all task/Jira project pair under jira_project_key
  unmountAllTasksRelevantToJiraProject: (jira_project_key, user_id) ->
    all_sprints_and_fix_versions_under_jira_project = @getAllStoredSprintsAndFixVersionsByJiraProjectKey jira_project_key
    all_sprint_ids_under_jira_project = _.map all_sprints_and_fix_versions_under_jira_project.sprints, (sprint) -> sprint.id
    all_fix_version_ids_under_jira_project = _.map all_sprints_and_fix_versions_under_jira_project.fix_versions, (fix_version) -> fix_version.id

    # Remove issue keys under this Jira Project under this Justdo
    tasks_query =
      $or: [
        jira_project_key: jira_project_key
      ,
        jira_issue_key:
          $regex: "#{jira_project_key}-\\d"
          $options: "i"
      ,
        jira_sprint_mountpoint_id:
          $in: all_sprint_ids_under_jira_project
      ,
        jira_fix_version_mountpoint_id:
          $in: all_fix_version_ids_under_jira_project
      ]
    tasks_ops =
      $set:
        updated_by: user_id
        jira_project_key: null
        jira_issue_key: null
        jira_sprint_mountpoint_id: null
        jira_fix_version_mountpoint_id: null
        jira_mountpoint_type: null

    @tasks_collection.update tasks_query, tasks_ops, {multi: true}

    # Remove mountpoint record in projects collection
    justdo_query =
      "justdo_jira_integration.mounted_tasks.jira_project_key": jira_project_key
    justdo_ops =
      $pull:
        "justdo_jira_integration.mounted_tasks":
          jira_project_key: jira_project_key
    @projects_collection.update justdo_query, justdo_ops, {multi: true}

    return

  getAvailableJiraProjects: (justdo_id, user_id) ->
    if not APP.projects.isProjectAdmin justdo_id, user_id
      throw @_error "permission-denied"

    client = @getJiraClientForJustdo(justdo_id).v2

    projects = await client.projects.getAllProjects()
    projects = _.map projects, (project) -> _.pick(project, "name", "key", "id")

    return projects

  getJiraProjectByIdOrKey: (justdo_id, project_id_or_key) ->
    client = @getJiraClientForJustdo(justdo_id).v2
    project = await client.projects.getProject {projectIdOrKey: project_id_or_key}

    return project

  setJustdoIdandTaskIdToJiraIssue: (justdo_id, task_id, issue_id_or_key) ->
    # XXX Need to think of how to store and fetch Jira customfields ids for task_id and justdo_id
    client = @getJiraClientForJustdo(justdo_id).v2
    req =
      issueIdOrKey: issue_id_or_key
      notifyUsers: false
      fields:
        [JustdoJiraIntegration.task_id_custom_field_id]: task_id
        [JustdoJiraIntegration.project_id_custom_field_id]: justdo_id
        [JustdoJiraIntegration.last_updated_custom_field_id]: new Date()
    client.issues.editIssue req
    .catch (err) -> console.error err.data
    return

  getJustdosIdsAndTasksIdsfromMountedJiraProjectKey: (jira_project_key) ->
    query =
      "justdo_jira_integration.mounted_tasks.jira_project_key": jira_project_key
    query_option =
      fields:
        "justdo_jira_integration.mounted_tasks.$": 1

    mounted_project = @projects_collection.findOne(query, query_option)
    if mounted_project?
      mounted_task = mounted_project.justdo_jira_integration.mounted_tasks[0]
      return_obj =
        justdo_id: mounted_project._id
        task_id: mounted_task.task_id
        jira_project_key: mounted_task.jira_project_key
      return return_obj
    return

  # XXX If we don't support mounting the same Jira project over mulitple tasks, only taks_id is needed
  getJiraProjectKeyFromJustdoIdAndMountedTaskId: (justdo_id, task_id) ->
    query =
      _id: justdo_id
      "justdo_jira_integration.mounted_tasks.task_id": task_id
    query_option =
      fields:
        "justdo_jira_integration.mounted_tasks.$": 1
    return @projects_collection.findOne(query, query_option)?.justdo_jira_integration?.mounted_tasks?[0]?.jira_project_key

  # Since sprints are associated with boards instead of Jira project,
  # we will have to fetch all associated Jira projects via API call.
  getJiraProjectsByBoardId: (board_id, options) ->
    {client, justdo_id} = options
    if not client?
      client = @getJiraClientForJustdo(justdo_id).agile

    return client.board.getProjects {boardId: board_id}

  getAllBoardsAssociatedToJiraProject: (jira_project_key_or_id, options) ->
    {client, justdo_id} = options
    if not client?
      client = @getJiraClientForJustdo(justdo_id).agile

    return client.board.getAllBoards({projectKeyOrId: jira_project_key_or_id})

  # Since sprints are associated with boards instead of Jira project,
  # we will have to fetch all associated Jira projects via API call.
  getAllAssociatedJiraProjectsByBoardId: (board_id, options) ->
    {client, justdo_id} = options
    if not client?
      client = @getJiraClientForJustdo(justdo_id).agile

    return client.board.getProjects {boardId: board_id}

  fetchAndStoreAllFixVersionsUnderJiraProject: (jira_project_key, options) ->
    # XXX As this method is called upon server restart, maybe move the checkings to methods.coffee?
    {client, justdo_id, jira_server_id} = options
    if not client?
      client = @getJiraClientForJustdo(justdo_id).v2

    jira_server_id = @getJiraServerIdFromApiClient client

    client.projectVersions.getProjectVersions({projectIdOrKey: jira_project_key})
      .then (fix_versions) =>
        for fix_version in fix_versions
          fix_version.id = parseInt fix_version.id
        query =
          "server_info.id": jira_server_id
        ops =
          $set:
            "jira_projects.#{jira_project_key}.fix_versions": fix_versions
        @jira_collection.update query, ops
        return
      .catch (err) -> console.error err

    return

  fetchAndStoreAllSprintsUnderJiraProject: (jira_project_key, options) ->
    # XXX As this method is called upon server restart, maybe move the checkings to methods.coffee?
    {client, justdo_id, jira_server_id} = options
    if not client?
      client = @getJiraClientForJustdo(justdo_id).agile

    jira_server_id = @getJiraServerIdFromApiClient client

    boards = await @getAllBoardsAssociatedToJiraProject jira_project_key, {client}

    promises = []

    for board in boards.values
      board_id = board.id
      promise = client.board.getAllSprints({boardId: board_id})
        .then (sprints) =>
          query =
            "server_info.id": jira_server_id
          ops =
            $set:
              "jira_projects.#{jira_project_key}.sprints": sprints.values
          @jira_collection.update query, ops
          return
        .catch (err) -> console.error err
      promises.push promise

    return Promise.all promises

  # Also creates proxy users for emails that aren't registered in Justdo
  fetchAndStoreAllUsersUnderJiraProject: (jira_project_key, options) ->
    {client, justdo_id} = options
    if not client?
      client = @getJiraClientForJustdo(justdo_id).v2

    jira_server_id = @getJiraServerIdFromApiClient client

    users_info = await client.userSearch.findAssignableUsers {project: jira_project_key}
    jira_accounts = []
    proxy_users_to_be_created = []

    for user_info in users_info
      if user_info.accountType is "atlassian"
        # If the email isn't recognized, create a proxy user.
        # XXX Temp fix for email API permission issue. Remove the first if statment when resolved/Jira server is in use
        if _.isEmpty user_info.emailAddress
          user_info.emailAddress = @_getHarcodedEmailByAccountId user_info.accountId

        if not Accounts.findUserByEmail(user_info.emailAddress)?
          [first_name, last_name] = user_info.displayName.split " "
          profile = {first_name, last_name}
          proxy_users_to_be_created.push {email: user_info.emailAddress, profile: profile}

        jira_accounts.push
          jira_account_id: user_info.accountId
          email: user_info.emailAddress
          display_name: user_info.displayName
          active: user_info.active
          timezone: user_info.timezone
          locale: user_info.locale
          avatar_url: user_info.avatarUrl

    APP.accounts.createProxyUsers(proxy_users_to_be_created)

    query =
      "server_info.id": jira_server_id
    ops =
      $set:
        "jira_projects.#{jira_project_key}.jira_accounts": jira_accounts
    @jira_collection.update query, ops

    return

  getJiraUser: (justdo_id, options) ->
    check options.account_id, Match.Maybe String
    check options.email, Match.Maybe String
    client = @getJiraClientForJustdo(justdo_id)
    if options?.email?
      query = {query: options.email}
    if options?.account_id?
      query = {accountId: options.account_id}
    return await client.v2.userSearch.findUsers query

  getJiraServerInfoFromJustdoId: (justdo_id) ->
    check justdo_id, String
    return @jira_collection.findOne({justdo_ids: justdo_id}, {fields: {server_info: 1}})?.server_info

  getJiraServerIdFromApiClient: (client) ->
    return client?.config?.host?.replace "https://api.atlassian.com/ex/jira/", ""

  getJiraClientForJustdo: (justdo_id) ->
    check justdo_id, String
    jira_server_id = @getJiraServerInfoFromJustdoId(justdo_id).id
    if not (client = @clients?[jira_server_id])?
      throw @_error "client-not-found"
    return client

  getAllMountedJiraProjectKeysAsSetByJustdoIds: (justdo_ids) ->
    check justdo_ids, [String]

    all_mounted_jira_project_keys = new Set()
    query =
      _id:
        $in: justdo_ids
      "justdo_jira_integration.mounted_tasks.jira_project_key":
        $exists: true
    query_options =
      fields:
        "justdo_jira_integration.mounted_tasks.jira_project_key": 1
    @projects_collection.find(query, query_options).forEach (project_doc) ->
      for mounted_task in project_doc.justdo_jira_integration.mounted_tasks
        if not all_mounted_jira_project_keys.has mounted_task.jira_project_key
          all_mounted_jira_project_keys.add mounted_task.jira_project_key
      return

    return all_mounted_jira_project_keys

  getJiraProjectKeyByIdIfMounted: (jira_project_id) ->
    query =
      "justdo_jira_integration.mounted_tasks.jira_project_id": "#{jira_project_id}"
    query_options =
      fields:
        "justdo_jira_integration.mounted_tasks.$": 1
    return @projects_collection.findOne(query, query_options)?.justdo_jira_integration?.mounted_tasks?[0]?.jira_project_key

  # XXX for demo only
  _getHarcodedEmailByAccountId: (jira_account_id) ->
    users =
      "62987073e5408700696717a3":"daniel@justdo.com"
      "62986f1cd9eae9006f35f026": "galit@justdo.com"
      "629870dbd9eae9006f35f10b": "brian@justdo.com"
      "62a6f9d3192edb006f9dc233": "brian+1@justdo.com"
      "62bc0c35118b20bee2bbdf52": "brian+2@justdo.com"
      "62bc0c35ec4c0d377f9fcf00": "brian+3@justdo.com"

    return users[jira_account_id] or "#{jira_account_id}@justdo.com"

  getAllJiraProjectMembers: (jira_project_key) ->
    jira_query =
      "jira_projects.#{jira_project_key}":
        $ne: null
    jira_options =
      fields:
        "jira_projects.#{jira_project_key}.jira_accounts.email": 1
        "jira_projects.#{jira_project_key}.jira_accounts.display_name": 1
        "jira_projects.#{jira_project_key}.jira_accounts.locale": 1
    return @jira_collection.findOne(jira_query, jira_options)?.jira_projects?[jira_project_key]?.jira_accounts

  addJiraProjectMembersToJustdo: (justdo_id, emails) ->
    for email in emails
      try
        APP.projects.inviteMember justdo_id, {email: email}, @_getJustdoAdmin justdo_id
      catch e
        if e.error isnt "member-already-exists"
          throw e
    return

  getJustdoUserIdByJiraAccountId: (jira_project_key, jira_account_id) ->
    query =
      "jira_projects.#{jira_project_key}.jira_accounts.jira_account_id": jira_account_id
    query_options =
      fields:
        "jira_projects.#{jira_project_key}.jira_accounts.$": 1

    user_email = @jira_collection.findOne(query, query_options)?.jira_projects?[jira_project_key]?.jira_accounts?[0]?.email
    return Accounts.findUserByEmail(user_email)._id

  getAllStoredSprintsAndFixVersionsByJiraProjectKey: (jira_project_key) ->
    return @jira_collection.findOne({"jira_projects.#{jira_project_key}": {$ne: null}}, {fields: {"jira_projects.#{jira_project_key}": 1}})?.jira_projects?[jira_project_key]

  getClientByHost: (host) ->
    jira_doc = @jira_collection.findOne({"server_info.url": host}, {fields: {"server_info": 1}})
    if (jira_server_id = jira_doc?.server_info?.id)?
      if (client = @clients[jira_server_id])?
        return client
      throw @_error "client-not-found"

  getAllRelevantJiraFieldIds: ->
    relevant_field_ids = _.map JustdoJiraIntegration.justdo_field_to_jira_field_map, (field) -> field.id or field.name
    return relevant_field_ids.concat ["project", "parent", "assignee", JustdoJiraIntegration.task_id_custom_field_id, JustdoJiraIntegration.project_id_custom_field_id, JustdoJiraIntegration.last_updated_custom_field_id]
