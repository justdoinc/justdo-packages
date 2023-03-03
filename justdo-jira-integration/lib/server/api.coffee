{URL, URLSearchParams} = JustdoHelpers.url
root = exports ? @
root.URL = URL
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

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in grid-control-middlewares.coffee
    @_setupGridMiddlewares()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    @setupJiraRoutes()

    @clients = {}
    @deleted_issue_ids = new Set()
    @deleted_sprint_ids = new Set()
    @removed_sprint_parent_issue_pairs = new Set()
    @deleted_fix_version_ids = new Set()
    @removed_fix_version_parent_issue_pairs = new Set()
    @pending_connection_test = {}
    @issues_with_discrepancies = []
    @ongoing_checkpoint = null

    # XXX if oauth1 in use
    @oauth_token_to_justdo_id = {}

    # Whenever we refresh Jira API token, ensure all existing mounted issues are up to date.
    @on "afterJiraApiTokenRefresh", (jira_server_id) =>
      @pending_connection_test = {}
      @ensureIssueDataIntegrityAndMarkCheckpoint jira_server_id
      return

    # Refresh Api token immidiately upon server startup
    @_setupJiraClientForAllJustdosWithRefreshToken()

    # OAuth1 access token has 5 years of life according to doc
    # https://developer.atlassian.com/cloud/jira/platform/jira-rest-api-oauth-authentication/ (Step 4)
    if @getAuthTypeIfJiraInstanceIsOnPerm() isnt "oauth1"
      # Refresh Api token every set interval
      @_registerDbMigrationScriptForRefreshingAccessToken()

    # Check alive for Jira Api client and webhook and attempt to repair.
    @_registerDbMigrationScriptForWebhookHealthCheck()

    # Maintain issue data integrity
    @_registerDbMigrationScriptForDataIntegrityCheck()

    @_setupInvertedFieldMap()

    @_registerAllowedConfs()

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

  _registerAllowedConfs: ->
    Projects.registerAllowedConfs
      [JustdoJiraIntegration.projects_collection_jira_doc_id]:
        require_admin_permission: true
        value_matcher: String
        allow_change: true
        allow_unset: false
    return

  _getAllJustdoAdmins: (justdo_id) ->
    admins = @projects_collection.findOne({_id: justdo_id, "members.is_admin": true}, {fields: {"members.$.user_id": 1}}).members
    return _.map admins, (admin) -> admin.user_id

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

    jira_project_id = parseInt req_body.issue.fields.project.id
    jira_doc_id = @getJiraDocIdFromJustdoId justdo_id
    custom_field_map = _.indexBy @getCustomFieldMapByJiraProjectId(jira_doc_id, jira_project_id), "jira_field_id"
    fields_schema = _.extend {}, @tasks_collection.simpleSchema()._schema, GridControlCustomFields.getProjectCustomFieldsDefinitions(APP.projects, justdo_id)

    # issue_updated
    if options?.use_changelog
      {changelog} = req_body
      fields_map =
        $set: {}
        $addToSet: {}
        $pull: {}

      for changed_item in changelog.items
        jira_field_id = changed_item.fieldId or changed_item.field
        # Temp workaround for on-perm Jira installations that has field name/id discrepencies with Jira cloud
        if (alt_jira_field_id = JustdoJiraIntegration.alt_field_name_map[jira_field_id])?
          jira_field_id = alt_jira_field_id

        if not (justdo_field_id = JustdoJiraIntegration.jira_field_to_justdo_field_map[jira_field_id])? and not (custom_jira_field_map = custom_field_map[jira_field_id])?
          continue

        if _.isString justdo_field_id
          default_jira_field_map = JustdoJiraIntegration.justdo_field_to_jira_field_map[justdo_field_id]
          field_type = default_jira_field_map.type
        else
          justdo_field_id = custom_jira_field_map.justdo_field_id
          field_type = @translateJustdoFieldTypeToMappedFieldType fields_schema[justdo_field_id]

        if default_jira_field_map?.mapper?
          field_val = default_jira_field_map.mapper.call @, justdo_id, changed_item, "justdo", req_body
        else if field_type is "string"
          field_val = changed_item.toString
        else if field_type in ["select", "multi_select"]
          field_obj = {justdo_field_id, jira_field_id, field_val: changed_item}
          field_val = JustdoJiraIntegration.primitive_field_mappers[field_type].call @, justdo_id, field_obj, "justdo", req_body
        else if field_type in ["date", "number"]
          field_val = JustdoJiraIntegration.primitive_field_mappers[field_type].call @, justdo_id, changed_item, "justdo", req_body
        else if field_type is "array"
          {fromString, toString} = changed_item

          # From null to something, assume add/set
          if _.isNull(fromString) and _.isString(toString)
            if not fields_map.$addToSet[justdo_field_id]?
              fields_map.$addToSet[justdo_field_id] =
                $each: []
            fields_map.$addToSet[justdo_field_id].$each.push toString

          # From something to null, assume remove/unset
          if _.isString(fromString) and _.isNull(toString)
            if not fields_map.$pull[justdo_field_id]?
              fields_map.$pull[justdo_field_id] =
                $in: []
            fields_map.$pull[justdo_field_id].$in.push fromString

          continue
        else
          field_val = changed_item.to

        fields_map.$set[justdo_field_id] = field_val
    # issue_created
    else
      {fields} = req_body.issue
      fields_map = {}
      field_ids_to_sync = _.union _.keys(custom_field_map), _.keys(JustdoJiraIntegration.jira_field_to_justdo_field_map)

      for jira_field_id in field_ids_to_sync
        jira_field = fields[jira_field_id]
        justdo_field_id = JustdoJiraIntegration.jira_field_to_justdo_field_map[jira_field_id] or custom_field_map[jira_field_id]?.justdo_field_id
        default_jira_field_def = JustdoJiraIntegration.justdo_field_to_jira_field_map[justdo_field_id]
        field_type = default_jira_field_def?.type or @translateJustdoFieldTypeToMappedFieldType fields_schema[justdo_field_id]

        if not (_.has fields, jira_field_id) and (_.isEmpty jira_field) and not (_.isNumber jira_field) and not (_.isBoolean jira_field)
          if options?.include_null_values is true
            fields_map[justdo_field_id] = null
          continue

        if default_jira_field_def?.mapper?
          field_val = default_jira_field_def.mapper.call @, justdo_id, jira_field, "justdo", req_body
        else if field_type is "string"
          field_val = jira_field
        else if field_type in ["select", "multi_select"]
          field_obj = {justdo_field_id, jira_field_id, field_val: jira_field}
          field_val = JustdoJiraIntegration.primitive_field_mappers[field_type].call @, justdo_id, field_obj, "justdo", req_body
        else if field_type in ["date", "number"]
          field_val = JustdoJiraIntegration.primitive_field_mappers[field_type].call @, justdo_id, jira_field, "justdo", req_body
        else if _.isArray jira_field
          fields_map[justdo_field_id] = []
          for sub_field in jira_field
            fields_map[justdo_field_id].push sub_field.name
          continue
        else
          field_val = jira_field?.name

        fields_map[justdo_field_id] = field_val

    return fields_map

  _mapJustdoFieldsToJiraFields: (justdo_id, task_doc, modifier) ->
    fields_to_update =
      fields: {}
      transition: {}

    jira_project_id = task_doc.jira_project_id
    jira_doc_id = @getJiraDocIdFromJustdoId justdo_id
    custom_field_map = _.indexBy @getCustomFieldMapByJiraProjectId(jira_doc_id, jira_project_id), "justdo_field_id"
    fields_schema = _.extend {}, @tasks_collection.simpleSchema()._schema, GridControlCustomFields.getProjectCustomFieldsDefinitions(APP.projects, justdo_id)

    for field_id, field_val of modifier.$set
      if not (core_jira_field_map = JustdoJiraIntegration.justdo_field_to_jira_field_map[field_id])? and not (custom_jira_field_map = custom_field_map[field_id])?
        continue

      jira_field_id = core_jira_field_map?.id or core_jira_field_map?.name or custom_jira_field_map?.jira_field_id

      if core_jira_field_map?.mapper?
        # Some updates require using different APIs.
        # If the mapper doesn't return a value, assume the update are performed inside the mapper.
        if (mapped_field_val = core_jira_field_map.mapper.call @, justdo_id, field_val, "jira", task_doc)?
          if field_id is "state"
            fields_to_update.transition =
              id: mapped_field_val
          else
            fields_to_update.fields[jira_field_id] = mapped_field_val
      else if (field_type = @translateJustdoFieldTypeToMappedFieldType fields_schema[field_id]) in ["date", "number"]
        fields_to_update.fields[jira_field_id] = JustdoJiraIntegration.primitive_field_mappers[field_type].call @, justdo_id, field_val, "jira", task_doc
      else if field_type in ["select", "multi_select"]
        field_obj = {jira_field_id, field_val, justdo_field_id: field_id}
        fields_to_update.fields[jira_field_id] = JustdoJiraIntegration.primitive_field_mappers[field_type].call @, justdo_id, field_obj, "jira", task_doc
      else
        fields_to_update.fields[jira_field_id] = field_val

    return fields_to_update

  _createTaskFromJiraIssue: (justdo_id, parent_path, jira_issue_body, options) ->
    # XXX Use schema for checking options?

    jira_issue_key = jira_issue_body.key
    jira_issue_id = jira_issue_body.id
    jira_project_id = jira_issue_body.fields.project.id
    justdo_admin_id = @_getJustdoAdmin justdo_id

    task_fields =
      project_id: justdo_id
      jira_issue_key: jira_issue_key
      jira_issue_id: jira_issue_id
      jira_project_id: jira_project_id
      jira_last_updated: new Date()

    _.extend task_fields, @_mapJiraFieldsToJustdoFields justdo_id, {issue: jira_issue_body}

    perform_as = justdo_admin_id

    gc = APP.projects._grid_data_com
    created_task_id = ""
    try
      created_task_id = gc.addChild parent_path, task_fields, perform_as
    catch e
      @logger.error jira_issue_key, parent_path, "failed", e

    Meteor.defer =>
      if task_fields.jira_issue_reporter?
        APP.tasks_changelog_manager.logChange
          field: "jira_issue_reporter"
          label: "Issue Reporter"
          change_type: "custom"
          task_id: created_task_id
          by: task_fields.jira_issue_reporter
          new_value: "became reporter"

      # The following handles adding parent of created task to their sprint/fix version.
      # Note that add parent is called only when the created task has a different sprint/fix version that the parent task.
      if @getIssueTypeRank(task_fields.jira_issue_type, jira_project_id) > -1
        parent_task = @tasks_collection.findOne GridDataCom.helpers.getPathItemId parent_path, {fields: {jira_sprint: 1, jira_fix_version: 1}}
        if (issue_sprint = task_fields.jira_sprint)? and (issue_sprint isnt parent_task.jira_sprint)
          # XXX Uncomment for debug info
          # console.log "-----Adding to sprint-----"
          # console.log "Task id:", created_task_id
          # console.log "Sprint:", issue_sprint
          # if options?.sprints_mountpoints?
          #   console.log "Sprint mountpoints:", options.sprints_mountpoints
          if not (sprint_parent_task_id = options?.sprints_mountpoints?[issue_sprint])?
            active_sprint = @_getActiveSprintOfIssue jira_issue_body.fields[JustdoJiraIntegration.sprint_custom_field_id]
            if (sprint_id = active_sprint.id or active_sprint.match(/id=\d+/)?[0]?.replace("id=", ""))?
              sprint_parent_task_id = @tasks_collection.findOne({jira_sprint_mountpoint_id: parseInt sprint_id}, {fields: {_id: 1}})?._id
          # XXX This if condition catches cases where a sprint is closed and we do not create a task out of it.
          if sprint_parent_task_id?
            gc.addParent created_task_id, {parent: sprint_parent_task_id}, perform_as

        if not _.isEmpty(fix_versions = jira_issue_body.fields.fixVersions)
          for fix_version in fix_versions
            if not _.contains parent_task.jira_fix_version, fix_version.name
              # XXX Uncomment for debug info
              # console.log "-----Adding to fix version-----"
              # console.log "Task id:", created_task_id
              # console.log "Fix version:", fix_version.name
              # if options?.fix_versions_mountpoints?
              #   console.log "Fix version mountpoints:", options.fix_versions_mountpoints
              if not (fix_version_parent_task_id = options?.fix_versions_mountpoints?[fix_version.name])?
                fix_version_parent_task_id = @tasks_collection.findOne({jira_fix_version_mountpoint_id: parseInt fix_version.id}, {fields: {_id: 1}})?._id
              # XXX This if condition catches cases where a fix version is closed and we do not create a task out of it.
              if fix_version_parent_task_id?
                gc.addParent created_task_id, {parent: fix_version_parent_task_id}, perform_as

      @setJustdoIdandTaskIdToJiraIssue justdo_id, created_task_id, jira_issue_id

    @logger.debug jira_issue_key, "created_task_id", created_task_id

    return created_task_id

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
      url: new URL("/plugins/servlet/oauth/request-token", @jira_server_host).toString()
      method: "POST"
    req.headers = oauth.toHeader oauth.authorize req

    res = Meteor.wrapAsync(HTTP.post)(req.url, req)
    if res?.statusCode isnt 200
      # Error occured
      return res
    res_params = new URLSearchParams res.content
    oauth_token = res_params.get "oauth_token"
    @oauth_token_to_justdo_id[oauth_token] = justdo_id
    return new URL("/plugins/servlet/oauth/authorize?oauth_token=#{oauth_token}", @jira_server_host).toString()

  getOAuth2LoginLink: (justdo_id, user_id) ->
    if not APP.projects.isProjectAdmin justdo_id, user_id
      throw @_error "permission-denied"

    if @getAuthTypeIfJiraInstanceIsOnPerm() is "oauth2"
      base_url = new URL "/rest/oauth2/latest/authorize", @jira_server_host
      oauth2_scopes = "SYSTEM_ADMIN"

    if @isJiraInstanceCloud()
      base_url = new URL "https://auth.atlassian.com/authorize"
      oauth2_scopes = "offline_access read:jql:jira write:board-scope:jira-software read:board-scope.admin:jira-software read:project:jira write:sprint:jira-software read:board-scope:jira-software read:issue-details:jira read:sprint:jira-software read:jira-work manage:jira-project manage:jira-configuration read:jira-user write:jira-work manage:jira-webhook manage:jira-data-provider"

    params = new URLSearchParams
      audience: "api.atlassian.com"
      client_id: @client_id
      redirect_uri: new URL "/jira/oAuthCallback/", @getRootUrlForCallbacksAndRedirects()
      scope: oauth2_scopes
      state: justdo_id
      response_type: "code"
      prompt: "consent"

    base_url.search = params

    return base_url

  _registerDbMigrationScriptForRefreshingAccessToken: ->
    self = @

    common_batched_migration_options =
      delay_before_checking_for_new_batches: JustdoJiraIntegration.access_token_update_rate_ms
      delay_between_batches: 5000
      mark_as_completed_upon_batches_exhaustion: false
      batch_size: 1
      collection: APP.collections.Jira
      static_query: false
      queryGenerator: ->
        query =
          access_token_updated:
            $lte: JustdoHelpers.getDateMsOffset(-1 * JustdoJiraIntegration.access_token_update_rate_ms)
        query_options =
          fields:
            refresh_token: 1
        return {query, query_options}
      batchProcessor: (jira_collection_cursor) ->
        num_processed = 0
        jira_collection_cursor.forEach (jira_doc) ->
          self.refreshJiraAccessToken jira_doc
          num_processed += 1

        return num_processed

    APP.justdo_db_migrations.registerMigrationScript "refresh-jira-api-token", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)
    return

  # XXX Currently this script only support a single Jira instance.
  _registerDbMigrationScriptForWebhookHealthCheck: ->
    self = @

    common_batched_migration_options =
      delay_before_checking_for_new_batches: JustdoJiraIntegration.webhook_connection_check_rate_ms
      delay_between_batches: 10000 # 10 secs
      mark_as_completed_upon_batches_exhaustion: false
      batch_size: 1
      collection: APP.collections.Jira
      static_query: false
      queryGenerator: ->
        query =
          last_webhook_connection_check:
            $lte: JustdoHelpers.getDateMsOffset(-1 * JustdoJiraIntegration.webhook_connection_check_rate_ms)
        query_options =
          fields:
            server_info: 1
            refresh_token: 1
        return {query, query_options}
      batchProcessor: (jira_collection_cursor) ->
        num_processed = 0

        if not _.isEmpty self.pending_connection_test
          @logProgress "The last issue update was not received on webhook. Attempting to refresh API token and ensuring all mounted tasks are up to date."
          _.each self.pending_connection_test, (test_obj) -> self.refreshJiraAccessToken test_obj.jira_doc_id, {emit_event: true}
        else
          jira_collection_cursor.forEach (jira_doc) =>
            jira_server_id = jira_doc.server_info?.id
            if not (client = self.clients[jira_server_id]?.v2)?
              @logProgress "Client not exist for Jira instance #{jira_server_id}."
              return

            if not (jira_issue_id = self.tasks_collection.findOne({jira_issue_id: {$ne: null}}, {sort: {jira_last_updated: -1}, fields: {jira_issue_id: 1, refresh_token: 1}})?.jira_issue_id)?
              @logProgress "No mounted issue found for Jira instance #{jira_server_id}."
              return

            date_for_connection_test = new Date()
            self.pending_connection_test[jira_issue_id] = {date: date_for_connection_test, jira_doc_id: jira_doc._id}

            req =
              issueIdOrKey: jira_issue_id
              notifyUsers: false
              fields:
                [JustdoJiraIntegration.last_updated_custom_field_id]: date_for_connection_test

            client.issues.editIssue req
              .then => @logProgress "Issue update sent successfully."
              .catch (err) =>
                @logProgress "Edit issue failed. Attempting to refresh API token."
                self.refreshJiraAccessToken jira_doc, {emit_event: true}
                return

          num_processed += 1

        return num_processed

    APP.justdo_db_migrations.registerMigrationScript "jira-webhook-healthcheck", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)
    return

  # XXX This script assumes there is only one connected Jira instance
  _registerDbMigrationScriptForDataIntegrityCheck: ->
    self = @

    common_batched_migration_options =
      delay_before_checking_for_new_batches: JustdoJiraIntegration.data_integrity_check_rate_ms
      delay_between_batches: JustdoJiraIntegration.data_integrity_check_rate_ms
      mark_as_completed_upon_batches_exhaustion: false
      batch_size: 100000 # XXX Should be unlimited
      collection: APP.collections.Jira
      static_query: false
      queryGenerator: ->
        query =
          last_data_integrity_check:
            $lte: JustdoHelpers.getDateMsOffset -1 * (JustdoJiraIntegration.data_integrity_check_rate_ms + JustdoJiraIntegration.data_integrity_margin_of_safety)
        query_options =
          fields:
            "server_info.id": 1
            last_data_integrity_check: 1
            jira_projects: 1

        return {query, query_options}
      batchProcessor: (jira_collection_cursor) ->
        num_processed = 0

        jira_collection_cursor.forEach (jira_doc) ->
          num_processed += 1
          self.ensureIssueDataIntegrityAndMarkCheckpoint jira_doc

          return

        return num_processed

    APP.justdo_db_migrations.registerMigrationScript "jira-data-integrity-check", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)

    return

  _setupJiraClientForAllJustdosWithRefreshToken: ->
    first_call = true
    @jira_collection.find({access_token: {$exists: true}}, {fields: {server_info: 1, refresh_token: 1, access_token: 1, token_secret: 1}}).forEach (jira_doc) =>
      console.log "Refreshing Jira OAuth2 access token for Jira server #{jira_doc.server_info?.name}"
      if first_call
        @refreshJiraAccessToken jira_doc, {emit_event: true}
        first_call = false
      else
        @refreshJiraAccessToken jira_doc
      return

  _parseAndStoreJiraCredentials: (res, options) ->
    if res.statusCode is 200
      if @getAuthTypeIfJiraInstanceIsOnPerm() is "oauth1"
        res_params = new URLSearchParams res.content
        access_token = res_params.get "oauth_token"
        token_secret = res_params.get "oauth_token_secret"
        jira_clients_config =
          newErrorHandling: true
          authentication:
            oauth:
              consumerKey: @consumer_key
              consumerSecret: @private_key
              accessToken: access_token
              tokenSecret: token_secret
      else
        {access_token, refresh_token} = res.data
        jira_clients_config =
          newErrorHandling: true
          authentication:
            oauth2:
              accessToken: access_token

      if @isJiraInstanceCloud()
        get_accessible_resources_options =
          headers:
            Authorization: "Bearer #{access_token}"
            Accept: "application/json "
        res = await HTTP.get "https://api.atlassian.com/oauth/token/accessible-resources", get_accessible_resources_options
        server_info = res.data?[0]
        jira_client_host = new URL(server_info.id, "https://api.atlassian.com/ex/jira/").toString()
      else
        server_info =
          id: "private-server"
          url: @jira_server_host
          name: "Private Jira Server"
          scopes: ["SYSTEM_ADMIN"]
        jira_client_host = @jira_server_host

      query =
        "server_info.id": server_info.id
      ops =
        $set:
          access_token: access_token
          server_info: server_info
          access_token_updated: new Date()
      if refresh_token?
        ops.$set.refresh_token = refresh_token
        ops.$set.refresh_token_updated = new Date()
      if token_secret?
        ops.$set.token_secret = token_secret

      @jira_collection.upsert query, ops

      jira_clients_config.host = jira_client_host
      @clients[server_info.id] =
        v2: new Version2Client jira_clients_config
        agile: new AgileClient jira_clients_config
      client = @clients[server_info.id]

      if options?.emit_event
        @emit "afterJiraApiTokenRefresh", server_info.id

      return server_info.id

  convertOAuth2RequestAndEndpointForJiraServer: (end_point, request) ->
    request.headers["Content-Type"] = "application/x-www-form-urlencoded"
    end_point = new URL end_point
    for key, value of request.data
      end_point.searchParams.set key, value
    end_point = end_point.toString()
    delete request.data
    return end_point

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
        redirect_uri: new URL "/jira/oAuthCallback/", @getRootUrlForCallbacksAndRedirects()
    # Route for oAuth callback
    Router.route "/jira/oAuthCallback", {where: "server"}
      .get ->
        @response.end("<script>window.close();</script>")
        # code is used to obtain access_token
        # state is the custom state key we pass. Currently is the justdo_id where we perform the authorization
        {code, state:justdo_id, oauth_token} = @request.query # equiv. justdo_id = state
        # If oauth_token exists, assume OAuth1 toward Jira server is in use
        if oauth_token?
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
            url: new URL("/plugins/servlet/oauth/access-token", self.jira_server_host).toString()
            method: "POST"

          get_oauth_token_req.headers = oauth.toHeader oauth.authorize get_oauth_token_req, {key: oauth_token}

          HTTP.post get_oauth_token_req.url, get_oauth_token_req, (err, res) ->
            if err?
              console.error err.response
              return
            jira_server_id = await self._parseAndStoreJiraCredentials res
            jira_doc_id = self.jira_collection.findOne({"server_info.id": jira_server_id}, {fields: {_id: 1}})._id
            APP.projects.configureProject justdo_id, {[JustdoJiraIntegration.projects_collection_jira_doc_id]: jira_doc_id}, self._getJustdoAdmin justdo_id
            return

        # If code exists, assume OAuth2 toward Jira cloud is in use.
        if code?
          get_oauth_token_endpoint = self.get_oauth_token_endpoint
          get_oauth_token_req = _.extend {}, GET_OAUTH_TOKEN_REQUEST_TEMPLATE
          get_oauth_token_req.data.code = code

          if self.getAuthTypeIfJiraInstanceIsOnPerm() is "oauth2"
            # Jira server oauth2 expects the data to be encoded into the url, instead of the post body.
            get_oauth_token_endpoint = self.convertOAuth2RequestAndEndpointForJiraServer get_oauth_token_endpoint, get_oauth_token_req

          HTTP.post get_oauth_token_endpoint, get_oauth_token_req, (err, res) ->
            if err?
              console.error "[justdo-jira-integration] Failed to get access token", err.response
              return

            jira_server_id = await self._parseAndStoreJiraCredentials res
            jira_doc_id = self.jira_collection.findOne({"server_info.id": jira_server_id}, {fields: {_id: 1}})._id
            APP.projects.configureProject justdo_id, {[JustdoJiraIntegration.projects_collection_jira_doc_id]: jira_doc_id}, self._getJustdoAdmin justdo_id
            return

    # Route for webhook
    Router.route "/jira/webhook", {where: "server"}
      .post ->
        @response.end()
        event_type = @request.body.webhookEvent
        # If a user got deleted, Jira cloud will send something like this over webhook
        # {
        #     "accountId": "62bc0c35ec4c0d377f9fcf00",
        #     "username": "ug:6506c242-6910-4955-914a-1284790049a2"
        # }
        if self.isJiraInstanceCloud() and not event_type? and @request.body.accountId?
          event_type = "user_deleted"

        self.jiraWebhookEventHandlers[event_type]?.call(self, @request.body)
        return

    return

  refreshJiraAccessToken: (jira_doc, options) ->
    self = @
    if _.isString jira_doc
      jira_doc = @jira_collection.findOne jira_doc, {fields: {refresh_token: 1, access_token: 1, token_secret: 1, "server_info.id": 1}}

    if options?.emit_event
      @emit "beforeJiraApiTokenRefresh", jira_doc.server_info.id

    if @getAuthTypeIfJiraInstanceIsOnPerm() is "oauth1"
      jira_clients_config =
        newErrorHandling: true
        host: @jira_server_host
        authentication:
          oauth:
            consumerKey: @consumer_key
            consumerSecret: @private_key
            accessToken: jira_doc.access_token
            tokenSecret: jira_doc.token_secret
      @clients[jira_doc.server_info?.id] =
        v2: new Version2Client jira_clients_config
        agile: new AgileClient jira_clients_config
      if options?.emit_event
        @emit "afterJiraApiTokenRefresh", jira_doc.server_info.id
    else
      req =
        headers:
          "Content-Type": "application/json"
        data:
          grant_type: "refresh_token"
          refresh_token: jira_doc.refresh_token
          client_id: @client_id
          client_secret: @client_secret

      get_oauth_token_endpoint = self.get_oauth_token_endpoint

      if @getAuthTypeIfJiraInstanceIsOnPerm() is "oauth2"
        get_oauth_token_endpoint = @convertOAuth2RequestAndEndpointForJiraServer get_oauth_token_endpoint, req

      HTTP.post get_oauth_token_endpoint, req, (err, res) =>
        if err?
          console.error err
          console.error "[justdo-jira-integration] Failed to refresh access token", err.response
          return
        @_parseAndStoreJiraCredentials res, options
        return

    return

  mountTaskWithJiraProject: (task_id, jira_project_id, user_id) ->
    justdo_id = APP.collections.Tasks.findOne(task_id, {fields: {project_id: 1}})?.project_id
    jira_doc_id = @getJiraDocIdFromJustdoId justdo_id

    if not @isJiraIntegrationInstalledOnJustdo justdo_id
      throw @_error "not-supported", "Jira integration is not installed on this project: #{justdo_id}"

    if not APP.projects.isProjectAdmin justdo_id, user_id
      throw @_error "permission-denied"

    @fetchJiraProjectKeyById justdo_id, jira_project_id
    client = @getJiraClientForJustdo justdo_id

    # Ensure all project members is either normal or proxy users, and add them as member to the target Justdo.
    @fetchAndStoreAllUsersUnderJiraProject jira_project_id, {justdo_id: justdo_id, client: client.v2}
    # Fetch all sprints and fixed versions under the current Jira project
    @fetchAndStoreAllSprintsUnderJiraProject jira_project_id, {justdo_id: justdo_id, client: client.agile}
    @fetchAndStoreAllFixVersionsUnderJiraProject jira_project_id, {justdo_id: justdo_id, client: client.v2}
    @fetchAndStoreIssueTypesUnderJiraProject jira_project_id, {justdo_id: justdo_id, client: client.v2}

    # Remove previous mountpoint record of the same Jira project, and clear all issue keys in relevant to that mountpoint.
    @unmountAllTasksRelevantToJiraProject jira_project_id, user_id

    # If the Jira project is mounted in another JustDo, clear custom field mappings that involves JustDo custom field.
    if @getJustdosIdsAndTasksIdsfromMountedJiraProjectId(jira_project_id)?.justdo_id isnt justdo_id
      @removeJustdoCustomFieldMapping justdo_id, jira_project_id

    justdo_admin_id = @_getJustdoAdmin justdo_id
    # XXX If the Justdo admin is guarenteed to also be a member of the moutned Jira project,
    # XXX change the following to an array and remove default value.
    # Get an array of user_ids of Jira project members to be inserted in tasks created from Jira issue
    user_ids_to_be_added_to_child_tasks = new Set @_getAllJustdoAdmins(justdo_id)
    jira_user_emails = @getAllUsersInJiraInstance(@getJiraDocIdFromJustdoId justdo_id).map (user) ->
      user_ids_to_be_added_to_child_tasks.add Accounts.findUserByEmail(user.email)?._id
      return user.email
    user_ids_to_be_added_to_child_tasks = Array.from user_ids_to_be_added_to_child_tasks

    # Ensures all Jira project members has access to current Justdo
    @addJiraProjectMembersToJustdo justdo_id, jira_user_emails

    @tasks_collection.update task_id, {$set: {jira_project_id: jira_project_id, jira_mountpoint_type: "root"}}

    # Add task members to the mounted task
    APP.projects.bulkUpdateTasksUsers justdo_id,
      tasks: [task_id]
      members_to_add: user_ids_to_be_added_to_child_tasks
    , justdo_admin_id

    # Setup mountpoints for sprints and fix versions
    gc = APP.projects._grid_data_com

    jira_query_options =
      fields:
        "jira_projects.#{jira_project_id}": 1
    jira_project_sprints_and_fix_versions = @jira_collection.findOne(jira_doc_id, jira_query_options)
    jira_project_sprints_and_fix_versions = jira_project_sprints_and_fix_versions?.jira_projects?[jira_project_id]

    # Create the three special task that groups all the sprints and fix versions, and all the tasks
    # roadmap_mountpoint currently holds all the issues
    roadmap_mountpoint_task_id = gc.addChild "/#{task_id}/", {title: "Roadmap", project_id: justdo_id, jira_project_id: jira_project_id, jira_mountpoint_type: "roadmap", state: "nil", jira_last_updated: new Date()}, justdo_admin_id
    # XXX Might need some special treatment for these two tasks and their child
    # XXX Like bolding the title, prevent removal, etc etc
    sprints_mountpoint_task_id = gc.addChild "/#{task_id}/", {title: "Sprints", project_id: justdo_id, jira_project_id: jira_project_id, jira_mountpoint_type: "sprints", state: "nil", jira_last_updated: new Date()}, justdo_admin_id
    fix_versions_mountpoint_task_id = gc.addChild "/#{task_id}/", {title: "Fix Versions", project_id: justdo_id, jira_project_id: jira_project_id, jira_mountpoint_type: "fix_versions", state: "nil", jira_last_updated: new Date()}, justdo_admin_id
    # Since the row style data cannot be inserted along addChild, we perform the update here.
    @tasks_collection.update {_id: {$in: [roadmap_mountpoint_task_id, sprints_mountpoint_task_id, fix_versions_mountpoint_task_id]}}, {$set: {"jrs:style": {bold: true}}}, {multi: true}

    # Create all the sprints and fix versions as task that groups all the issues under the same attribute
    sprints_to_mountpoint_task_id = {}
    if jira_project_sprints_and_fix_versions.sprints?
      for sprint in jira_project_sprints_and_fix_versions.sprints
        sprints_to_mountpoint_task_id[sprint.name] = @_createSprintTask sprint, sprints_mountpoint_task_id, justdo_id, jira_project_id

    fix_versions_to_mountpoint_task_id = {}
    if jira_project_sprints_and_fix_versions.fix_versions
      for fix_version in jira_project_sprints_and_fix_versions.fix_versions
        # Ignore released and archived versions
        if fix_version.archived or fix_version.released
          continue
        task_fields =
          project_id: justdo_id
          jira_project_id: jira_project_id
          title: fix_version.name
          jira_fix_version_mountpoint_id: fix_version.id
          state: "nil"
          jira_last_updated: new Date()
        if fix_version.startDate?
          task_fields.start_date = moment(fix_version.startDate).format("YYYY-MM-DD")
        if fix_version.releaseDate?
          task_fields.due_date = moment(fix_version.releaseDate).format("YYYY-MM-DD")
        fix_versions_to_mountpoint_task_id[fix_version.name] = gc.addChild "/#{fix_versions_mountpoint_task_id}/", task_fields, justdo_admin_id

    # Get Jira server time
    server_info = await client.v2.serverInfo.getServerInfo()

    relevant_jira_field_ids = @getAllRelevantJiraFieldIds()

    # Search for all issues under the Jira project and create tasks in Justdo
    # issueSearch has searchForIssuesUsingJql() and searchForIssuesUsingJqlPost()
    # Both works the same way except the latter one uses POST to support a larger query
    # For consistency with future development, only searchForIssuesUsingJqlPost() is used.
    issue_search_body =
      jql: """project=#{jira_project_id} and "Parent Link" is empty and status!=done"""
      maxResults: JustdoJiraIntegration.jql_issue_search_results_limit
      fields: relevant_jira_field_ids
    issue_search_cb = (res) =>
      {issues} = res

      while (issue = issues.shift())?
        issue_fields = issue.fields

        parent_id = null
        path_to_add = "/#{task_id}/#{roadmap_mountpoint_task_id}/"

        if (parent_key = issue_fields.parent?.key or issue_fields[JustdoJiraIntegration.epic_link_custom_field_id])?
          if not (parent_task_id = @tasks_collection.findOne({project_id: justdo_id, jira_project_id: parseInt(jira_project_id), jira_issue_key: parent_key}, {fields: {_id: 1}})?._id)?
            issues.push issue
            # XXX Remove console.log when missing child issue is resolved.
            console.log "Parent not found. Issue: #{issue.key}, parent: ", issue_fields.parent
            continue

          path_to_add += "#{parent_task_id}/"

        create_task_from_jira_issue_options =
          sprints_mountpoints: sprints_to_mountpoint_task_id
          fix_versions_mountpoints: fix_versions_to_mountpoint_task_id

        created_task_id = @_createTaskFromJiraIssue justdo_id, path_to_add, issue, create_task_from_jira_issue_options

        # Mark webhook and data integrity checkpoint
        query =
          "server_info.id": @getJiraServerIdFromApiClient client.v2
        ops =
          $set:
            last_data_integrity_check: server_info.serverTime
            last_webhook_connection_check: server_info.serverTime
        @jira_collection.update query, ops

        if @getIssueTypeRank(issue_fields?.issuetype?.name, jira_project_id) > -1
          jql = """project=#{jira_project_id} and "Parent Link"=#{issue.key} and status!=done """
          client.v2.issueSearch.searchForIssuesUsingJqlPost {jql, maxResults: JustdoJiraIntegration.jql_issue_search_results_limit, fields: relevant_jira_field_ids}
            .then issue_search_cb
            .catch (err) -> console.error err

      return

    client.v2.issueSearch.searchForIssuesUsingJqlPost issue_search_body
      .then issue_search_cb
      .catch (err) -> console.error err

    return

  # Unmounts a single task/Jira project pair
  unmountTaskWithJiraProject: (justdo_id, jira_project_id, user_id) ->
    jira_project_id = parseInt jira_project_id
    jira_doc_id = @getJiraDocIdFromJustdoId justdo_id

    if not @isJiraIntegrationInstalledOnJustdo justdo_id
      throw @_error "not-supported", "Jira integration is not installed on this project: #{justdo_id}"

    if not APP.projects.isProjectAdmin justdo_id, user_id
      throw @_error "permission-denied"

    # Remove issue keys under this Jira Project under this Justdo
    tasks_query =
      project_id: justdo_id
      jira_project_id: jira_project_id

    tasks_ops =
      $set:
        updated_by: user_id

    # Unset all core Jira fields
    for field_id of @tasks_collection_schema
      tasks_ops.$set[field_id] = null

    @tasks_collection.update tasks_query, tasks_ops, {multi: true}

    jira_ops =
      $unset:
        "jira_projects.#{jira_project_id}": 1
    @jira_collection.update jira_doc_id, jira_ops

    return

  # Unmounts all task/Jira project pair under jira_project_id
  unmountAllTasksRelevantToJiraProject: (jira_project_id, user_id) ->
    jira_project_id = parseInt jira_project_id

    # Remove issue ids under this Jira Project under this Justdo
    tasks_query =
      jira_project_id: jira_project_id

    tasks_ops =
      $set:
        updated_by: user_id

    # Unset all core Jira fields
    for field_id of @tasks_collection_schema
      tasks_ops.$set[field_id] = null

    @tasks_collection.update tasks_query, tasks_ops, {multi: true}

    return

  getAvailableJiraProjects: (justdo_id, user_id) ->
    if not APP.projects.isProjectAdmin justdo_id, user_id
      throw @_error "permission-denied"

    client = @getJiraClientForJustdo(justdo_id).v2

    projects = await client.projects.getAllProjects()
    projects = _.map projects, (project) -> _.pick(project, "name", "key", "id")

    return projects

  fetchJiraProjectKeyById: (justdo_id, jira_project_id) ->
    client = @getJiraClientForJustdo(justdo_id).v2
    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "projects.getProject", {projectIdOrKey: jira_project_id}, client
    if err?
      err = err?.response?.data or err
      console.error "[justdo_jira_integration] Failed to fetch project key", err
      return

    query =
      "server_info.id": @getJiraServerIdFromApiClient client
    ops =
      $set:
        "jira_projects.#{jira_project_id}.key": res.key
    @jira_collection.update query, ops

    return

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
      .catch (err) =>
        @logger.error "[justdo-jira-integration] Failed to set Justdo task and project id to Jira issue", err.data

    return

  getJustdosIdsAndTasksIdsfromMountedJiraProjectId: (jira_project_id) ->
    if _.isString jira_project_id
      jira_project_id = parseInt jira_project_id
    query =
      jira_project_id: jira_project_id
      jira_mountpoint_type: "roadmap"
    query_option =
      fields:
        project_id: 1
        jira_project_id: 1

    mounted_task = @tasks_collection.findOne(query, query_option)
    if mounted_task?
      return_obj =
        justdo_id: mounted_task.project_id
        task_id: mounted_task._id
        jira_project_id: mounted_task.jira_project_id
      return return_obj
    return

  # Since sprints are associated with boards instead of Jira project,
  # we will have to fetch all associated Jira projects via API call.
  getJiraProjectsByBoardId: (board_id, options) ->
    {client, justdo_id} = options
    if not client?
      client = @getJiraClientForJustdo(justdo_id).agile

    return client.board.getProjects {boardId: board_id}

  fetchAndStoreIssueTypesUnderJiraProject: (jira_project_id, options) ->
    {client} = options
    if not client?
      throw @_error "client-not-found"

    jira_server_id = @getJiraServerIdFromApiClient client

    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "projects.getProject", {projectIdOrKey: jira_project_id}, client
    if err?
      console.error err

    project = res

    query =
      "server_info.id": jira_server_id
    ops =
      $set:
        "jira_projects.#{jira_project_id}.issue_types": project.issueTypes
    @jira_collection.update query, ops

    return

  getAllBoardsAssociatedToJiraProject: (jira_project_key_or_id, options) ->
    {client, justdo_id} = options
    if not client?
      client = @getJiraClientForJustdo(justdo_id).agile

    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "board.getAllBoards", {projectKeyOrId: jira_project_key_or_id}, client
    if err?
      console.error err

    return res

  # Since sprints are associated with boards instead of Jira project,
  # we will have to fetch all associated Jira projects via API call.
  getAllAssociatedJiraProjectsByBoardId: (board_id, options) ->
    {client, justdo_id} = options
    if not client?
      client = @getJiraClientForJustdo(justdo_id).agile

    return client.board.getProjects {boardId: board_id}

  fetchAndStoreAllFixVersionsUnderJiraProject: (jira_project_id, options) ->
    {client} = options
    if not client?
      throw @_error "client-not-found"

    jira_server_id = @getJiraServerIdFromApiClient client

    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "projectVersions.getProjectVersions", {projectIdOrKey: jira_project_id}, client
    if err?
      console.error err

    fix_versions = res

    for fix_version in fix_versions
      fix_version.id = parseInt fix_version.id

    query =
      "server_info.id": jira_server_id
    ops =
      $set:
        "jira_projects.#{jira_project_id}.fix_versions": fix_versions
    @jira_collection.update query, ops
    return

  fetchAndStoreAllSprintsUnderJiraProject: (jira_project_id, options) ->
    {client} = options
    if not client?
      throw @_error "client-not-found"

    jira_server_id = @getJiraServerIdFromApiClient client

    boards = @getAllBoardsAssociatedToJiraProject jira_project_id, {client}

    for board in boards.values
      board_id = board.id
      {err, res} = @pseudoBlockingJiraApiCallInsideFiber "board.getAllSprints", {boardId: board_id}, client
      if err?
        console.error err

      sprints = res

      query =
        "server_info.id": jira_server_id
      ops =
        $set:
          "jira_projects.#{jira_project_id}.sprints": sprints.values
      @jira_collection.update query, ops

    return

  _createProxyUserIfEmailNotRecognized: (jira_project_id, jira_users, client) ->
    if not _.isArray jira_users
      jira_users = [jira_users]

    justdo_id = @tasks_collection.findOne({jira_project_id}, {fields: {project_id: 1}})?.project_id
    account_id_to_email_map = @jiraAccountIdToJustdoMemberEmails justdo_id, client

    jira_user_objects = []
    proxy_users_to_be_created = []
    created_user_ids = []

    for user_info in jira_users
      # If the email isn't recognized, create a proxy user.
      # XXX Temp fix for email API permission issue. Remove the first if statment when resolved/Jira server is in use
      if _.isEmpty user_info.emailAddress
        account_id_or_key = user_info.accountId or user_info.key
        user_info.emailAddress = account_id_to_email_map[account_id_or_key] or @_getHardcodedEmailByAccountId account_id_or_key

      if not APP.accounts.userExists user_info.emailAddress
        [first_name, last_name] = user_info.displayName.split " "
        profile = {first_name, last_name}
        proxy_users_to_be_created.push {email: user_info.emailAddress, profile: profile}

      jira_user_obj =
        jira_account_id: user_info.accountId or user_info.key
        email: user_info.emailAddress
        display_name: user_info.displayName
        active: user_info.active
        timezone: user_info.timezone
        locale: user_info.locale
        avatar_url: user_info.avatarUrls
        account_type: user_info.accountType
      # Jira on-perm doesn't have account type; It has a user name.
      if @isJiraInstanceCloud()
        jira_user_obj.account_type = user_info.accountType
      else
        jira_user_obj.username = user_info.name

      jira_user_objects.push jira_user_obj

    if not _.isEmpty proxy_users_to_be_created
      created_user_ids = APP.accounts.createProxyUsers(proxy_users_to_be_created)

    return {jira_user_objects, created_user_ids}

  jiraAccountIdToJustdoMemberEmails: (justdo_id, client) ->
    if not client?
      throw @_error "client-not-found"

    justdo_member_emails = _.map @projects_collection.findOne(justdo_id, {fields: {members: 1}})?.members, (member) ->
      return APP.accounts.getUserById(member.user_id).emails[0].address

    ret = {}

    for email in justdo_member_emails
      {err, res} = @pseudoBlockingJiraApiCallInsideFiber "userSearch.findUsers", {query: email}, client
      if err?
        @logger.error err
        continue
      if not _.isEmpty res
        ret[res[0].accountId] = email

    return ret

  # Also creates proxy users for emails that aren't registered in Justdo
  fetchAndStoreAllUsersUnderJiraProject: (jira_project_id, options) ->
    {client} = options
    if not client?
      throw @_error "client-not-found"

    jira_server_id = @getJiraServerIdFromApiClient client

    find_assignable_users_req =
      project: jira_project_id
    # Jira server API supports project key only for findAssignableUsers()
    if @getAuthTypeIfJiraInstanceIsOnPerm()?
      find_assignable_users_req.project = @getJiraProjectKeyById jira_server_id, jira_project_id

    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "userSearch.findAssignableUsers", find_assignable_users_req, client
    if err?
      console.error "[justdo-jira-integration] Failed to fetch users from project #{jira_project_id}", e
      return

    users_info = res


    {jira_user_objects} = @_createProxyUserIfEmailNotRecognized jira_project_id, users_info, client

    query =
      "server_info.id": jira_server_id
    ops =
      $set:
        jira_users: jira_user_objects
    @jira_collection.update query, ops

    return

  getJiraUser: (justdo_id, options) ->
    check options.account_id, Match.Maybe String
    check options.email, Match.Maybe String

    jira_doc_id = @getJiraDocIdFromJustdoId justdo_id

    query =
      _id: jira_doc_id
    if _.isString options?.account_id
      query["jira_users.jira_account_id"] = options.account_id
    if _.isString options?.email
      query["jira_users.email"] = options.email
    query_options =
      fields:
        "jira_users.$": 1

    # First try to locate the user from our db. Use API to search for user only if it's not in our db.
    if (jira_user = @jira_collection.findOne(query, query_options)?.jira_users?[0])?
      jira_user.accountId = jira_user.jira_account_id
      return [jira_user]

    client = @getJiraClientForJustdo(justdo_id)

    query = {}

    if @getAuthTypeIfJiraInstanceIsOnPerm()? and options?.email?
      query.username = options.email

    if @isJiraInstanceCloud()
      # AccountId is only available for Jira cloud instances.
      if options?.account_id?
        query.accountId = options.account_id
      if options?.email?
        query.query = options.email

    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "userSearch.findUsers", query, client.v2
    if err?
      err = err?.response?.data or err
      console.error err
      return
    else
      return res

  getJiraServerIdFromApiClient: (client) ->
    if @getAuthTypeIfJiraInstanceIsOnPerm()?
      return "private-server"
    return client?.config?.host?.replace "https://api.atlassian.com/ex/jira/", ""

  getJiraClientForJustdo: (justdo_id) ->
    check justdo_id, String
    jira_server_id = @getJiraServerInfoFromJustdoId(justdo_id).id
    if not (client = @clients?[jira_server_id])?
      throw @_error "client-not-found"
    return client

  # XXX for demo only
  _getHardcodedEmailByAccountId: (jira_account_id) ->
    return "#{jira_account_id}@justdo.com"

  getAllUsersInJiraInstance: (jira_doc_id) ->
    jira_options =
      fields:
        "jira_users.email": 1
        "jira_users.display_name": 1
        "jira_users.locale": 1
    return @jira_collection.findOne(jira_doc_id, jira_options)?.jira_users

  addJiraProjectMembersToJustdo: (justdo_id, emails) ->
    if _.isString emails
      emails = [emails]

    for email in emails
      try
        APP.projects.inviteMember justdo_id, {email: email}
      catch e
        if e.error isnt "member-already-exists"
          throw e
    return

  getJustdoUserIdByJiraAccountIdOrEmail: (jira_project_id, jira_account_id_or_email) ->
    if JustdoHelpers.common_regexps.email.test jira_account_id_or_email
      user_email = jira_account_id_or_email
    else
      if _.isString jira_project_id
        jira_project_id = parseInt jira_project_id

      query =
        "jira_users.jira_account_id": jira_account_id_or_email
      query_options =
        fields:
          "jira_users.$": 1

      user_email = @jira_collection.findOne(query, query_options)?.jira_users?[0]?.email

    return Accounts.findUserByEmail(user_email)._id

  getClientByHost: (host) ->
    jira_doc = @jira_collection.findOne({"server_info.url": host}, {fields: {"server_info": 1}})
    if (jira_server_id = jira_doc?.server_info?.id)?
      if (client = @clients[jira_server_id])?
        return client
      throw @_error "client-not-found"

  # XXX This method supports only single Jira instance
  getAllRelevantJiraFieldIds: ->
    default_mapped_field_ids = _.map JustdoJiraIntegration.justdo_field_to_jira_field_map, (field) -> field.id or field.name
    custom_mapped_field_ids = []

    jira_doc = @jira_collection.findOne({}, {fields: {jira_projects: 1}})
    for jira_project_id, jira_project of jira_doc.jira_projects
      if not jira_project.custom_field_map?
        continue

      for field_map in jira_project.custom_field_map
        custom_mapped_field_ids.push field_map.jira_field_id

    return _.union default_mapped_field_ids, custom_mapped_field_ids, ["project", "parent", "assignee", JustdoJiraIntegration.epic_link_custom_field_id, JustdoJiraIntegration.task_id_custom_field_id, JustdoJiraIntegration.project_id_custom_field_id, JustdoJiraIntegration.last_updated_custom_field_id]

  isJustdoMountedWithJiraProject: (justdo_id) ->
    query =
      project_id: justdo_id
      jira_mountpoint_type: "root"
      jira_project_id:
        $ne: null

    return @tasks_collection.find(query).count() > 0

  assignIssueToSprint: (jira_issue_id, jira_sprint_id, justdo_id) ->
    client = @getJiraClientForJustdo(justdo_id).agile
    req =
      sprintId: jira_sprint_id
      issues: [jira_issue_id]

    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "sprint.moveIssuesToSprintAndRank", req, client

    if err?
      err = err?.response?.data or err
      console.error "[justdo-jira-integration] Assign issue to sprint failed" , err
      return false

    return true

  updateIssueFixVersion: (jira_issue_id, ops, justdo_id) ->
    ops = _.pick ops, "add", "remove"
    client = @getJiraClientForJustdo(justdo_id).v2

    req =
      issueIdOrKey: jira_issue_id
      notifyUsers: false
      update:
        fixVersions: []

    for op_type, fix_version_ids of ops
      if _.isString(fix_version_ids) or _.isNumber(fix_version_ids)
        req.update.fixVersions.push
          [op_type]:
            id: "#{fix_version_ids}"
      if _.isArray fix_version_ids
        for fix_version_id in fix_version_ids
          req.update.fixVersions.push
            [op_type]:
              id: "#{fix_version_id}"

    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "issues.editIssue", req, client

    if err?
      err = err?.response?.data or err
      console.error "[justdo-jira-integration] Assign issue to fix version failed" , err
      return false

    return true

  _searchIssueUsingJqlUntilMaxResults: (jira_server_id, issue_search_body, jira_server_time, options, responseProcessor) ->
    if _.isFunction options
      responseProcessor = options

    if not (client = @clients[jira_server_id]?.v2)?
      throw @_error "client-not-found"

    try
      res = await client.issueSearch.searchForIssuesUsingJqlPost issue_search_body
    catch err
      console.trace()
      err = err?.response?.data or err
      console.error "[justdo-jira-integration] Issue search failed.", err
      return

    await responseProcessor.call @, res, jira_server_time

    if @_ensureCheckpointProcessInControl jira_server_time
      if res.total > (new_start_at = res.startAt + res.maxResults)
        issue_search_body.startAt = new_start_at
        await @_searchIssueUsingJqlUntilMaxResults jira_server_id, issue_search_body, jira_server_time, options, responseProcessor
      else if _.isEmpty @issues_with_discrepancies
        console.log "[justdo-jira-integration] Data integrity check completed. No discrepencies found."
        if not options?.do_not_mark_checkpoint
          @markDataIntegrityCheckpoint jira_server_id, jira_server_time
      else if options?.perform_resync_if_discrepencies_found
        @resyncIssuesIfDiscrepenciesAreFound jira_server_id, jira_server_time, {do_not_mark_checkpoint: options?.do_not_mark_checkpoint}
    return

  getRootUrlForCallbacksAndRedirects: ->
    return process.env.JIRA_ROOT_URL_CUSTOM_DOMAIN or process.env.ROOT_URL

  getLastDataIntegrityCheckpointWithMarginOfSafety: (jira_server_id) ->
    query =
      last_data_integrity_check:
        $lte: JustdoHelpers.getDateMsOffset -1 * (JustdoJiraIntegration.data_integrity_check_rate_ms + JustdoJiraIntegration.data_integrity_margin_of_safety)
    query_options =
      last_data_integrity_check: 1
    return @jira_collection.findOne(query, query_options)?.last_data_integrity_check

  ensureIssueDataIntegrityAndMarkCheckpoint: (jira_doc, options) ->
    if _.isString jira_doc
      jira_doc_query =
        $or: [
          _id: jira_doc
        ,
          "server_info.id": jira_doc
        ]
      jira_doc_query_options =
        fields:
          "server_info.id": 1
          last_data_integrity_check: 1
          jira_projects: 1
      jira_doc = @jira_collection.findOne jira_doc_query, jira_doc_query_options

    if not (jira_server_id = jira_doc?.server_info?.id)?
      throw @_error "missing-argument", "Jira doc with server id, last_data_integrity_check and projects is required."

    if not (client = @clients[jira_server_id]?.v2)?
      throw @_error "client-not-found"

    if not (last_checkpoint = jira_doc.last_data_integrity_check)?
      last_checkpoint = @getLastDataIntegrityCheckpointWithMarginOfSafety()
    if not last_checkpoint?
      throw @_error "fatal", "The queried Jira doc #{jira_doc._id} has no data integrity checkpoint - This shouldn't happen!"
      return

    mounted_jira_project_ids = options?.jira_project_ids or _.keys jira_doc.jira_projects

    # Add margin of safety to last_checkpoint
    last_checkpoint = JustdoHelpers.getDateMsOffset -1 * JustdoJiraIntegration.data_integrity_margin_of_safety, new Date(last_checkpoint)

    issue_search_body =
      jql: """(project in (#{mounted_jira_project_ids.join ","}) and updated >= "#{moment(last_checkpoint).format("YYYY/MM/DD hh:mm")}" )"""
      maxResults: JustdoJiraIntegration.jql_issue_search_results_limit
      fields: options?.fields or @getAllRelevantJiraFieldIds()

    if not _.isEmpty(jira_issue_ids = @tasks_collection.find({jira_issue_id: {$ne: null}, jira_last_updated: {$gte: last_checkpoint}}, {fields: {jira_issue_id: 1}}).map (task_doc) -> task_doc.jira_issue_id)
      issue_search_body.jql += " or issue in (#{jira_issue_ids.join(",")})"

    console.log "[justdo-jira-integration] Ensuring issues updated since #{last_checkpoint} are up to date..."

    @issues_with_discrepancies = []

    # Get Jira server time
    server_info = await client.serverInfo.getServerInfo()

    if @isCheckpointAllowedToStart server_info.serverTime
      @_stopOngoingCheckpoint()
      @ongoing_checkpoint = server_info.serverTime

      checkIssuesIntegrity = (res, current_checkpoint) =>
        for issue in res.issues
          if not @_ensureCheckpointProcessInControl current_checkpoint
            return

          justdo_id = @getJustdoIdForIssue(issue) or issue.fields[JustdoJiraIntegration.project_id_custom_field_id]
          mapped_task_fields = @_mapJiraFieldsToJustdoFields justdo_id, {issue}, {include_null_values: true}
          if mapped_task_fields.owner_id is null
            mapped_task_fields.owner_id = @_getJustdoAdmin justdo_id
          if not (@tasks_collection.findOne(_.extend({jira_issue_id: parseInt issue.id}, mapped_task_fields), {fields: {_id: 1}}))?
            @issues_with_discrepancies.push issue.id
        return

      search_issue_using_jql_until_max_results_options =
        perform_resync_if_discrepencies_found: true
        do_not_mark_checkpoint: options?.do_not_mark_checkpoint
        fields: options?.fields

      @_searchIssueUsingJqlUntilMaxResults jira_server_id, issue_search_body, server_info.serverTime, search_issue_using_jql_until_max_results_options, checkIssuesIntegrity

      # Resync sprints and fix versions for each project under the Jira instanxce
      if _.isObject(jira_doc?.jira_projects) and not options?.sync_issues_only
        agile_client = @clients[jira_server_id].agile
        for jira_project_id of jira_doc.jira_projects
          @fetchAndStoreAllSprintsUnderJiraProject jira_project_id, {client: agile_client}
          @fetchAndStoreAllFixVersionsUnderJiraProject jira_project_id, {client: client}
          @fetchAndStoreAllUsersUnderJiraProject jira_project_id, {client: client}
          @fetchAndStoreIssueTypesUnderJiraProject jira_project_id, {client: client}
    else
      console.info "[justdo-jira-integration] Another checkpoint process is in progress (checkpoint: #{@ongoing_checkpoint})"

    return

  resyncIssuesIfDiscrepenciesAreFound: (jira_server_id, jira_server_time, options) ->
    console.warn "[justdo-jira-integration] Data inconsistency found in issues #{@issues_with_discrepancies}. Performing resync..."

    issue_search_body =
      jql: "issue in (#{@issues_with_discrepancies.join ","})"
      maxResults: JustdoJiraIntegration.jql_issue_search_results_limit
      fields: @getAllRelevantJiraFieldIds()

    resyncIssues = (res, current_checkpoint) =>
      for issue in res.issues
        if not @_ensureCheckpointProcessInControl current_checkpoint
          return

        justdo_id = @getJustdoIdForIssue issue
        fields = @_mapJiraFieldsToJustdoFields justdo_id, {issue}, {include_null_values: true, performing_resync: true}
        if not _.isEmpty fields
          # XXX updated_by is hardcoded to be justdo admin at the moment
          if @tasks_collection.update({jira_issue_id: parseInt(issue.id)}, {$set: _.extend {jira_last_updated: new Date(), updated_by: @_getJustdoAdmin justdo_id}, fields})
            @syncIssueFixVersionFromIssueBody issue

          # If nothing is updated, that means the task isn't created at all. Then we create the task if it's not done.
          else if fields.state isnt "done"
            if (parent = issue.fields.parent?.key)? or (parent = issue.fields[JustdoJiraIntegration.epic_link_custom_field_id])?
              parent_task_id = @tasks_collection.findOne({jira_issue_key: parent}, {fields: {_id: 1}})?._id
            else
              jira_project_id = parseInt issue.fields.project.id
              parent_task_id = @tasks_collection.findOne({jira_project_id: jira_project_id, jira_mountpoint_type: "roadmap"}, {fields: {_id: 1}})?._id
            @_createTaskFromJiraIssue justdo_id, "/#{parent_task_id}/", issue
      return

    await @_searchIssueUsingJqlUntilMaxResults jira_server_id, issue_search_body, jira_server_time, options, resyncIssues
    console.log "[justdo-jira-integration] Issues with discrepencies resynced."
    @issues_with_discrepancies = []
    return

  markDataIntegrityCheckpoint: (jira_server_id, jira_server_time) ->
    @_stopOngoingCheckpoint()
    @jira_collection.update {"server_info.id": jira_server_id}, {$set: {last_data_integrity_check: jira_server_time}}
    return

  getJustdoIdForIssue: (jira_issue_body) ->
    jira_project_id = parseInt jira_issue_body.fields.project.id
    justdo_id = @tasks_collection.findOne({jira_project_id: jira_project_id}, {fields: {project_id: 1}})?.project_id
    return justdo_id

  syncIssueFixVersionFromIssueBody: (jira_issue_body) ->
    # This method is meant to resolve the discrepencies between the jira_fix_version field in tasks, and the fix version parents.
    jira_issue_id = parseInt jira_issue_body.id
    jira_project_id = parseInt jira_issue_body.fields.project.id
    justdo_id = @getJustdoIdForIssue jira_issue_body or jira_issue_body.fields[JustdoJiraIntegration.project_id_custom_field_id]

    justdo_admin_id = @_getJustdoAdmin justdo_id
    grid_data = APP.projects._grid_data_com
    task_doc = @tasks_collection.findOne({jira_issue_id: jira_issue_id}, {fields: {jira_fix_version: 1, "parents2.parent": 1}})

    existing_fix_versions = new Map()

    # First we fetch all the existing parents that are fix version mountpoints
    query =
      _id:
        $in: _.map task_doc.parents2, (parent_obj) -> parent_obj.parent
      jira_fix_version_mountpoint_id:
        $ne: null
    query_options =
      fields:
        jira_fix_version_mountpoint_id: 1
    @tasks_collection.find(query, query_options).forEach (task_doc) -> existing_fix_versions.set parseInt(task_doc.jira_fix_version_mountpoint_id), task_doc._id

    # Then we cross check with the jira_fix_version field.
    # If a fix version id exists both in existing_fix_versions and jira_fix_version, do nothing. (nothing actually changed.)
    # If it only exists in jira_fix_version, perform add parent. (newly added fix version)
    if _.isArray(task_doc.jira_fix_version) and not _.isEmpty(task_doc.jira_fix_version)
      jira_query =
        "jira_projects.#{jira_project_id}.fix_versions.name":
          $in: task_doc.jira_fix_version
      jira_query_options =
        fields:
          "jira_projects.#{jira_project_id}.fix_versions": 1
      jira_doc = @jira_collection.findOne jira_query, jira_query_options

      for fix_version in jira_doc?.jira_projects?[jira_project_id]?.fix_versions
        if task_doc.jira_fix_version.includes fix_version.name
          fix_version_id = parseInt fix_version.id
          if not existing_fix_versions.delete fix_version_id
            query =
              jira_fix_version_mountpoint_id: fix_version_id
              jira_project_id: jira_project_id
            query_options:
              fields:
                _id: 1
            fix_version_mountpoint = @tasks_collection.findOne(query, query_options)
            try
              grid_data.addParent task_doc._id, {parent: fix_version_mountpoint?._id, order: 0}, justdo_admin_id
            catch e
              if e.error isnt "parent-already-exists"
                console.trace()
                console.error e

    # Finally we remove the old fix version parents
    existing_fix_versions.forEach (fix_version_mountpoint_task_id) ->
      try
        grid_data.removeParent "/#{fix_version_mountpoint_task_id}/#{task_doc._id}/", justdo_admin_id
      catch e
        if e.error isnt "unknown-parent"
          console.trace()
          console.error e
      return

    return

  _isCheckpointProcessInControl: (check_point) ->
    if not check_point?
      throw @_error "missing-argument", "Please provide checkpoint to check against."
    return check_point is @ongoing_checkpoint

  _ensureCheckpointProcessInControl: (check_point) ->
    if not (in_control = @_isCheckpointProcessInControl check_point)
      console.info "[justdo-jira-integration] Control for checkpoint #{check_point} lost."
    return in_control

  _stopOngoingCheckpoint: (show_alert) ->
    if not @ongoing_checkpoint?
      if show_alert
        console.info "[justdo-jira-integration] There is no ongoing checkpoint process"
    else
      @ongoing_checkpoint = null
    return

  resyncAllJiraRelevantData: (jira_doc, options) ->
    if @ongoing_checkpoint
      @_stopOngoingCheckpoint()

    if not jira_doc?
      throw @_error "missing-argument"
    # The idea is to use epoch when searching in JQL to fetch everything.
    # Since we subtract data_integrity_margin_of_safety in ensureIssueDataIntegrityAndMarkCheckpoint, it is being added to the epoch.
    jira_doc.last_data_integrity_check = JustdoHelpers.getDateMsOffset JustdoJiraIntegration.data_integrity_margin_of_safety, new Date 0

    @ensureIssueDataIntegrityAndMarkCheckpoint jira_doc, options

    return

  isCheckpointAllowedToStart: (check_point) ->
    return not @ongoing_checkpoint? or (check_point - @ongoing_checkpoint) > JustdoJiraIntegration.data_integrity_check_timeout

  pseudoBlockingJiraApiCallInsideFiber: (api_group_and_resource, req_body, client) ->
    fiber = JustdoHelpers.requireCurrentFiber()

    if not client?
      throw @_error "client-not-found"

    previous_path = null
    current_path = client

    for path in api_group_and_resource.split /\.|\//
      previous_path = current_path
      current_path = current_path[path]

    cb = (err, res) ->
      fiber.run {err, res}
      return

    if _.isNull req_body
      current_path.call previous_path, cb
    else
      current_path.call previous_path, req_body, cb

    return JustdoHelpers.fiberYield()

  getJiraFieldDef: (jira_doc_id) ->
    if @isJiraInstanceCloud()
      jira_server_id = @jira_collection.findOne(jira_doc_id, {fields: {"server_info.id": 1}})?.server_info?.id
    else
      jira_server_id = "private-server"

    client = @clients[jira_server_id].v2
    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "issueFields.getFields", null, client
    if err?
      throw err

    return res

  getJiraFieldDefByJiraProjectId: (jira_doc_id, jira_project_id) ->
    if @isJiraInstanceCloud()
      jira_server_id = @jira_collection.findOne(jira_doc_id, {fields: {"server_info.id": 1}})?.server_info?.id
    else
      jira_server_id = "private-server"

    client = @clients[jira_server_id].v2
    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "issues.getCreateIssueMeta", {projectIds: jira_project_id, expand: "projects.issuetypes.fields"}, client
    if err?
      throw err

    field_def = {}
    for issue_type in res.projects[0].issuetypes
      # XXX For fields with options: What if some issue type has more options in a field than the other?
      _.extend field_def, issue_type.fields

    return field_def

  # field_map is expected to be in the format of [{justdo_field_id, jira_field_id, id}, {justdo_field_id, jira_field_id, id}, ...]
  addCustomFieldPairs: (justdo_id, jira_project_id, field_map, user_id) ->
    jira_doc_id = @getJiraDocIdFromJustdoId justdo_id

    # field_map is checked by schema inside checkCustomFieldPairMapping()
    @checkCustomFieldPairMapping jira_doc_id, jira_project_id, field_map

    # The following block specifically handles option typed field pairs.
    custom_fields_to_create = []
    for field_pair in field_map
      if not (field_type = field_pair.justdo_field_id.replace "new_custom_", "")
        continue

      jira_field_def = @getJiraFieldDefByJiraProjectId jira_doc_id, jira_project_id

      if not (field_def = jira_field_def[field_pair.jira_field_id])?
        continue

      if not (field_options = field_def.allowedValues)?
        continue

      custom_field_id = Random.id()
      field_type_id = "basic-select"
      if field_type is "multi_select"
        field_type_id = "multi-select"
        custom_field_id = "custom-field-multi-select::#{custom_field_id}"
      field_pair.justdo_field_id = custom_field_id

      custom_field_def =
        custom_field_type_id: field_type_id
        default_width: 120
        field_id: custom_field_id
        field_type: field_type
        grid_editable_column: true
        grid_visible_column: true
        label: field_def.name
        field_options:
          select_options: _.map field_options, (field_option) -> {option_id: Random.id(), jira_option_id: field_option.id, label: field_option.name or field_option.value, bg_color: "00000000"}
      custom_fields_to_create.push custom_field_def

    if not _.isEmpty custom_fields_to_create
      existing_custom_fields = @projects_collection.findOne(justdo_id, {fields: custom_fields: 1})?.custom_fields or []
      APP.projects.setProjectCustomFields justdo_id, custom_fields_to_create.concat(existing_custom_fields), user_id

    ops =
      $addToSet:
        "jira_projects.#{jira_project_id}.custom_field_map":
          $each: field_map
    @jira_collection.update jira_doc_id, ops

    jira_fields = _.map field_map, (field_pair) -> field_pair.jira_field_id
    jira_fields.push "project" # Resync process require Jira project id from issue body
    @resyncAllJiraRelevantData jira_doc_id, {fields: jira_fields, jira_project_id: [jira_project_id], sync_issues_only: true, do_not_mark_checkpoint: true}

    return

  deleteCustomFieldPair: (justdo_id, jira_project_id, custom_field_pair_ids, user_id) ->
    if _.isString user_id
      APP.projects.requireProjectAdmin justdo_id, user_id

    if _.isString custom_field_pair_ids
      custom_field_pair_ids = [custom_field_pair_ids]

    jira_doc_id = @getJiraDocIdFromJustdoId justdo_id

    ops =
      $pull:
        "jira_projects.#{jira_project_id}.custom_field_map":
          id:
            $in: custom_field_pair_ids

    @jira_collection.update jira_doc_id, ops
    return

  removeJustdoCustomFieldMapping: (justdo_id, jira_project_id) ->
    jira_doc_id = @getJiraDocIdFromJustdoId justdo_id

    query =
      _id: jira_doc_id
      "jira_projects.#{jira_project_id}.custom_field_map":
        $ne: null
    query_options =
      fields:
        "jira_projects.#{jira_project_id}.custom_field_map": 1

    if not (jira_doc = @jira_collection.findOne jira_doc_id, query_options)
      return

    tasks_collection_schema = @tasks_collection.simpleSchema()._schema
    field_pair_ids_to_remove = []

    # If justdo_field_id isn't in tasks_collection_schema, the field is a custom field in Justdo.
    if _.isArray(custom_field_map = jira_doc.jira_projects?[jira_project_id]?.custom_field_map)
      for field_map in jira_doc.jira_projects[jira_project_id].custom_field_map
        if not _.has tasks_collection_schema, field_map.justdo_field_id
          field_pair_ids_to_remove.push field_map.id

    if not _.isEmpty field_pair_ids_to_remove
      @deleteCustomFieldPair justdo_id, jira_project_id, field_pair_ids_to_remove

    return

  _getJustdoCustomFieldDef: (justdo_id, justdo_custom_field_id) ->
    # Get the jira_option_id from projects_collection.custom_fields.
    query =
      _id: justdo_id
      "custom_fields.field_id": justdo_custom_field_id
    query_options =
      fields:
        "custom_fields.$": 1
    return @projects_collection.findOne(query, query_options)?.custom_fields?[0]
