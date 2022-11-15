{URL} = JustdoHelpers.url
_.extend JustdoJiraIntegration.prototype,
  _convertSprintToTaskFields: (sprint) ->
    task_fields =
      title: sprint.name
      jira_sprint_mountpoint_id: parseInt sprint.id
      state: "nil"
    if sprint.startDate?
      task_fields.start_date = moment(sprint.startDate).format("YYYY-MM-DD")
    if sprint.endDate?
      task_fields.end_date = moment(sprint.endDate).format("YYYY-MM-DD")

    return task_fields

  _convertFixVersionToTaskFields: (fix_version) ->
    task_fields =
      state: "nil"
      title: fix_version.name
      jira_fix_version_mountpoint_id: parseInt fix_version.id
    if (fix_version_start_date = fix_version.startDate or fix_version.userStartDate)?
      task_fields.start_date = moment(fix_version_start_date).format("YYYY-MM-DD")
    if (fix_version_release_date = fix_version.releaseDate or fix_version.userReleaseDate)?
      task_fields.due_date = moment(fix_version_release_date).format("YYYY-MM-DD")

    return task_fields

  _createFixVersionTask: (req_body, reopen=false) ->
    fix_version = req_body.version
    jira_project_id = fix_version.projectId

    # If the Jira project isn't mounted, ignore.
    if not (jira_doc_id = @isJiraProjectMounted jira_project_id)?
      return

    tasks_query =
      jira_project_id: jira_project_id
      jira_mountpoint_type: "fix_versions"
    tasks_options =
      project_id: 1
    if (fix_versions_mountpiont_task_doc = @tasks_collection.findOne(tasks_query, tasks_options))?
      justdo_id = fix_versions_mountpiont_task_doc.project_id
      justdo_admin_id = @_getJustdoAdmin justdo_id

      task_fields = _.extend @_convertFixVersionToTaskFields(fix_version),
        jira_project_id: jira_project_id
        project_id: justdo_id

      # Create the fix version task
      fix_version_task_id = APP.projects._grid_data_com.addChild "/#{fix_versions_mountpiont_task_doc._id}/", task_fields, justdo_admin_id

      # In case of a version reopen/unarchive, move all child tasks back to the fix version task.
      if reopen
        {err, res} = @pseudoBlockingJiraApiCallInsideFiber "issueSearch.searchForIssuesUsingJqlPost", {jql: "project=#{jira_project_id} and fixversion=#{fix_version.id} and status !=done", fields: ["project"]}, @getJiraClientForJustdo(justdo_id).v2
        if err?
          console.error "[justdo-jira-integration] Issue search failed", err
        grid_data = APP.projects._grid_data_com

        issue_ids = _.map res.issues, (issue) -> parseInt issue.id
        # XXX bulkAddParent can be used here, but it's not available yet.
        @tasks_collection.find({jira_issue_id: {$in: issue_ids}}, {fields: {_id: 1}}).forEach (task) ->
          grid_data.addParent task._id, {parent: fix_version_task_id}, justdo_admin_id
          return

    if not reopen
      jira_ops =
        $addToSet:
          "jira_projects.#{jira_project_id}.fix_versions": fix_version
      @jira_collection.update jira_doc_id, jira_ops
    return

  _updateFixVersionTask: (req_body) ->
    fix_version = req_body.version
    fix_version_id = parseInt fix_version.id
    jira_project_id = fix_version.projectId
    justdo_id = @tasks_collection.findOne({jira_project_id: jira_project_id}, {fields: {project_id: 1}})?.project_id

    # Temp workaround to fix a bug on Jira webhook: archived flag is not representing the truth over webhook.
    # Remove the API call after the bug is resolved.
    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "projectVersions.getVersion", {id: fix_version_id}, @getJiraClientForJustdo(justdo_id).v2
    if err?
      console.error "[justdo-jira-integration] Fetch version #{fix_version_id} failed", err
      return
    fix_version = res

    # If the Jira project isn't mounted, ignore.
    if not (jira_doc_id = @isJiraProjectMounted jira_project_id)?
      return

    jira_query =
      _id: jira_doc_id
      "jira_projects.#{jira_project_id}.fix_versions.id": fix_version_id

    tasks_query =
      jira_fix_version_mountpoint_id: fix_version_id
    fix_version_task = @tasks_collection.findOne(tasks_query, {fields: {project_id: 1}})

    if fix_version.released or fix_version.archived
      if fix_version_task?
        @_deleteFixVersionTask req_body
    else
      if fix_version_task?
        # Update the fix version task itself
        fields_to_update = _.extend @_convertFixVersionToTaskFields(fix_version),
          jira_last_updated: new Date()
          updated_by: @_getJustdoAdmin fix_version_task.project_id
        @tasks_collection.update tasks_query, {$set: fields_to_update}

        # Update the fix version field of issues
        old_fix_version_name = @jira_collection.findOne(jira_query, {fields: {"jira_projects.#{jira_project_id}.fix_versions.$": 1}})?.jira_projects?[jira_project_id]?.fix_versions?[0]?.name
        if old_fix_version_name isnt fix_version.name
          task_query =
            jira_project_id: jira_project_id
            jira_issue_id:
              $ne: null
            jira_fix_version: old_fix_version_name
          @tasks_collection.update task_query, {$set: {"jira_fix_version.$": fix_version.name}}, {multi: true}
      else
        @_createFixVersionTask req_body, true

    jira_ops =
      $set:
        "jira_projects.#{jira_project_id}.fix_versions.$": fix_version
    @jira_collection.update jira_query, jira_ops

    return

  _deleteFixVersionTask: (req_body, version_deleted_in_remote=false) ->
    fix_version_id = parseInt req_body.version.id
    jira_project_id = parseInt req_body.version.projectId

    if not (fix_version_task_doc = @tasks_collection.findOne({jira_project_id: jira_project_id, jira_fix_version_mountpoint_id: fix_version_id}, {fields: {project_id: 1}}))?
      console.error "[justdo-jira-integration] Fix version mountpoint not found. Remove failed."
      return

    grid_data = APP.projects._grid_data_com
    justdo_admin_id = @_getJustdoAdmin fix_version_task_doc.project_id

    child_task_ids = @_getIssueSubtreeTaskIdsUpToLevelsOfHierarchy fix_version_task_doc._id, {jira_fix_version: req_body.version.name}

    for task_id in child_task_ids?[0]
      if not version_deleted_in_remote
        @removed_fix_version_parent_issue_pairs.add "#{task_id}:#{fix_version_id}"
      grid_data.removeParent "/#{fix_version_task_doc._id}/#{task_id}/", justdo_admin_id

    fix_version_mountpoint_id = @tasks_collection.findOne({project_id: fix_version_task_doc.project_id, jira_project_id: jira_project_id, jira_mountpoint_type: "fix_versions"}, {fields: {_id: 1}})?._id
    @deleted_fix_version_ids.add fix_version_id
    grid_data.removeParent "/#{fix_version_mountpoint_id}/#{fix_version_task_doc._id}/", justdo_admin_id # Remove the fix version task at last

    if version_deleted_in_remote
      # Pull the fix version from issue
      if not _.isEmpty child_task_ids
        @tasks_collection.update {_id: {$in: _.flatten child_task_ids}, jira_fix_version: req_body.version.name}, {$pull: {jira_fix_version: req_body.version.name}}, {multi: true}

      # Remove the fix version metadata in Jira collection
      jira_query =
        "jira_projects.#{jira_project_id}.fix_versions.id": fix_version_id
      jira_ops =
        $pull:
          "jira_projects.#{jira_project_id}.fix_versions":
            id: fix_version_id
      @jira_collection.update jira_query, jira_ops
    return

  _getActiveSprintOfIssue: (sprints_array) ->
    if not sprints_array?
      return null

    if not _.isArray sprints_array
      throw @_error "invalid-argument"

    active_sprint = _.find sprints_array, (sprint) ->
      if _.isString sprint
        return sprint.match(/state=(?!CLOSED)/)?
      return sprint.state isnt "closed"
    return active_sprint

  _createSprintTask: (sprint, parent, justdo_id, jira_project_id) ->
    # Don't create tasks from closed sprints as it is non-editable in Jira
    if sprint.state is "closed"
      return

    task_fields = _.extend @_convertSprintToTaskFields(sprint),
      project_id: justdo_id
      jira_project_id: jira_project_id
      jira_last_updated: new Date()

    return APP.projects._grid_data_com.addChild "/#{parent}/", task_fields, @_getJustdoAdmin justdo_id

  _updateSprintTask: (req_body) ->
    {id, name, startDate, endDate, originBoardId, state} = req_body.sprint

    tasks_query =
      jira_sprint_mountpoint_id: parseInt id

    if not (justdo_id = @tasks_collection.findOne(tasks_query, {fields: {project_id: 1}})?.project_id)?
      # If sprint task is not found, the sprint may be closed and then re-opened.
      # Creation of sprint task will be handled below after getting all involved Jira projects.
      if state isnt "closed"
        # XXX Hack to get client without justdo_id. (Assuming there's only one Jira instance)
        client = _.values(@clients)[0].agile
      else
        return
    else
      client = @getJiraClientForJustdo(justdo_id).agile

      fields_to_update = _.extend @_convertSprintToTaskFields(req_body.sprint),
        jira_last_updated: new Date()
        updated_by: @_getJustdoAdmin justdo_id

      @tasks_collection.update tasks_query, {$set: fields_to_update}, {multi: true}

    jira_query =
      $or: []
    jira_ops =
      $set: {}

    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "board.getProjects", {boardId: originBoardId}, client
    if err?
      console.error err
      return

    # Updates Jira collection
    _.each res.values, (project_info) =>
      # If justdo_id isn't a string, that means the sprint wasn't there. We need to create a new sprint task
      jira_project_id = parseInt project_info.id

      if not _.isString justdo_id
        tasks_query =
          jira_project_id: jira_project_id
          jira_mountpoint_type: "sprints"
        tasks_options =
          project_id: 1

        if (sprint_mountpoint_task_doc = @tasks_collection.findOne(tasks_query, tasks_options))?
          justdo_id = sprint_mountpoint_task_doc.project_id
          sprint_task_id = @_createSprintTask req_body.sprint, sprint_mountpoint_task_doc._id, justdo_id, jira_project_id
          # In cases where a sprint is re-opened, we need to move the child issues back as well.
          {err, res} = @pseudoBlockingJiraApiCallInsideFiber "sprint.getIssuesForSprint", {sprintId: parseInt(id), fields: ["sprint", "project", "issuetype"], jql: "project=#{jira_project_id}"}, client
          if err?
            console.error err
          issue_ids = []
          for issue in res.issues
            # Each issue body in res will only contain the sprint field, and we use _mapJiraFieldsToJustdoFields to put the issues back to the original sprint.
            issue.fields[JustdoJiraIntegration.sprint_custom_field_id] = [issue.fields.sprint] # Just so _mapJiraFieldsToJustdoFields can detect the sprint field correctly.
            @_mapJiraFieldsToJustdoFields justdo_id, {issue}
            issue_ids.push parseInt issue.id
          @tasks_collection.update {jira_issue_id: {$in: issue_ids}}, {$set: {jira_sprint: name}}, {multi: true}

      jira_query.$or.push
        "jira_projects.#{jira_project_id}.sprints.id": id
      _.extend jira_ops.$set,
        "jira_projects.#{jira_project_id}.sprints.$.name": name
        "jira_projects.#{jira_project_id}.sprints.$.startDate": startDate or null
        "jira_projects.#{jira_project_id}.sprints.$.endDate": endDate or null
        "jira_projects.#{jira_project_id}.sprints.$.originBoardId": originBoardId
        "jira_projects.#{jira_project_id}.sprints.$.state": state

    @jira_collection.update jira_query, jira_ops
    return

  _deleteSprintTask: (req_body) ->
    sprint_id = parseInt req_body.sprint.id
    board_id = parseInt req_body.sprint.originBoardId
    grid_data = APP.projects._grid_data_com

    if not (client = _.values(@clients)?[0])?
      throw @_error "client-not-found"

    @deleted_sprint_ids.add sprint_id

    jira_query =
      $or: []
    jira_ops =
      $pull: {}

    @tasks_collection.find({jira_sprint_mountpoint_id: sprint_id}, {fields: {project_id: 1, jira_project_id: 1}}).forEach (sprint_task_doc) =>
      justdo_id = sprint_task_doc.project_id
      jira_project_id = sprint_task_doc.jira_project_id
      justdo_admin_id = @_getJustdoAdmin sprint_task_doc.project_id

      sprint_mountpoint_id = @tasks_collection.findOne({project_id: justdo_id, jira_project_id: jira_project_id, jira_mountpoint_type: "sprints"}, {fields: {_id: 1}})?._id

      subtree_task_ids = @_getIssueSubtreeTaskIdsUpToLevelsOfHierarchy sprint_task_doc._id, {jira_sprint: req_body.sprint.name}

      # We only need the path of immidiate child for removal
      for task_id in subtree_task_ids?[0]
        @removed_sprint_parent_issue_pairs.add "#{task_id}:#{sprint_id}"
        try
          grid_data.removeParent "/#{sprint_task_doc._id}/#{task_id}/", justdo_admin_id
        catch e
          if e.error not in ["parent-already-exists", "unknown-parent"]
            console.trace()
            console.error "[justdo-jira-integration] Relocate issue sprint parent failed.", e

      sprint_mountpoint_id = @tasks_collection.findOne({project_id: justdo_id, jira_project_id: jira_project_id, jira_mountpoint_type: "sprints"}, {fields: {_id: 1}})?._id
      try
        grid_data.removeParent "/#{sprint_mountpoint_id}/#{sprint_task_doc._id}/", justdo_admin_id # Remove the sprint task at last
      catch e
        if e.error not in ["parent-already-exists", "unknown-parent"]
          console.trace()
          console.error "[justdo-jira-integration] Relocate issue sprint parent failed.", e

      if not _.isEmpty subtree_task_ids
        # Remove the sprint field in all child tasks
        @tasks_collection.update {_id: {$in: _.flatten subtree_task_ids}}, {$unset: {jira_sprint: 1}}, {multi: true}

      # Remove the sprint metadata in Jira collection
      jira_query.$or.push
        "jira_projects.#{jira_project_id}.sprints.id": sprint_id
      jira_ops.$pull["jira_projects.#{jira_project_id}.sprints"] =
        id: sprint_id
      return

    @jira_collection.update jira_query, jira_ops

    return

  # XXX This method strictly support only one Jira instance
  _upsertJiraUser: (req_body, create_new_user=false) ->
    jira_user_id = req_body.user.key or req_body.user.accountId
    jira_user_email = req_body.user.emailAddress
    if not jira_user_email?
      jira_user_email = @_getHarcodedEmailByAccountId jira_user_id

    if not (client = _.values(@clients)?[0])?
      throw @_error "client-not-found"

    # The user info we receive over webhook doesn't include locale, timezone and other user preferences. We fetch those here via API.
    if @isJiraInstanceCloud()
      req = {accountId: jira_user_id}
    else
      req = {key: jira_user_id}

    {err, res} = @pseudoBlockingJiraApiCallInsideFiber "users.getUser", req, client.v2
    if err?
      console.error "[justdo-jira-integration] Failed to fetch user", err
      return

    jira_doc_id = null # To be fetched
    {jira_user_objects, created_user_ids} = @_createProxyUserIfEmailNotRecognized res
    if _.isEmpty created_user_ids
      created_user_id = APP.accounts.getUserByEmail(jira_user_email)._id
    else
      created_user_id = created_user_ids[0]

    query =
      "conf.#{JustdoJiraIntegration.projects_collection_jira_doc_id}":
        $ne: null
    query_options =
      fields:
        _id: 1
        "conf.#{JustdoJiraIntegration.projects_collection_jira_doc_id}": 1
    # Add user to JustDos that are associated with Jira instance
    @projects_collection.find(query, query_options).forEach (project_doc) =>
      if not _.isString jira_doc_id
        jira_doc_id = project_doc.conf[JustdoJiraIntegration.projects_collection_jira_doc_id]

      justdo_id = project_doc._id

      tasks_query =
        project_id: justdo_id
        jira_project_id:
          $ne: null
      root_tasks_to_add_members = @tasks_collection.find(tasks_query, {_id: 1}).map (task_doc) -> task_doc._id

      if not _.isEmpty root_tasks_to_add_members
        @addJiraProjectMembersToJustdo justdo_id, jira_user_email

        task_users_modifier =
          $addToSet:
            users:
              $each: [created_user_id]
        APP.projects.bulkUpdate justdo_id, root_tasks_to_add_members, task_users_modifier, @_getJustdoAdmin justdo_id
      return

    jira_ops =
      $addToSet:
        jira_users:
          $each: jira_user_objects
    @jira_collection.update jira_doc_id, jira_ops

    return

  jiraWebhookEventHandlers:
    "jira:issue_created": (req_body) ->
      {fields} = req_body.issue
      # Created from Justdo. Ignore.
      if fields[JustdoJiraIntegration.project_id_custom_field_id] or fields[JustdoJiraIntegration.task_id_custom_field_id]
        return
      jira_issue_id = parseInt req_body.issue.id
      jira_project_id = parseInt req_body.issue.fields.project.id

      if not _.isEmpty (mounted_justdo_and_task = @getJustdosIdsAndTasksIdsfromMountedJiraProjectId jira_project_id)
        {justdo_id, task_id} = mounted_justdo_and_task

        if not @isJiraIntegrationInstalledOnJustdo justdo_id
          return

        path_to_add = "/#{task_id}/"
        if fields.parent?
          if (parent_id = @tasks_collection.findOne({jira_issue_id: parseInt fields.parent.id}, {fields: {_id: 1}})._id)?
            path_to_add = "/#{parent_id}/"
        if (parent_issue_key = fields[JustdoJiraIntegration.epic_link_custom_field_id])?
          if (parent_id = @tasks_collection.findOne({jira_issue_key: parent_issue_key}, {fields: {_id: 1}})._id)?
            path_to_add = "/#{parent_id}/"

        user_ids_to_be_added_to_task = new Set()
        user_ids_to_be_added_to_task.add @_getJustdoAdmin justdo_id
        jira_user_emails = @getAllUsersInJiraInstance(@getJiraDocIdFromJustdoId justdo_id).map (user) ->
          user_ids_to_be_added_to_task.add Accounts.findUserByEmail(user.email)?._id
          return user.email
        user_ids_to_be_added_to_task = Array.from user_ids_to_be_added_to_task
        @_createTaskFromJiraIssue justdo_id, path_to_add, req_body.issue

      return
    "jira:issue_updated": (req_body) ->
      jira_issue_id = parseInt req_body.issue.id
      jira_project_id = parseInt req_body.issue.fields.project.id

      # Updates from Justdo. Either check for a match in pending_connection_test or ignore..
      if (last_updated_changelog_item = _.find req_body.changelog.items, (item) -> item.field is "jd_last_updated")?
        # Delete record in pending_connection_test if we receive the update we send.
        received_updated_date = new Date last_updated_changelog_item.toString
        if (last_update_date = @pending_connection_test?[jira_issue_id]?.date)? and (received_updated_date - last_update_date is 0)
          console.log "[justdo-db-migrations] [jira-webhook-healthcheck] Issue update received via webhook."
          @jira_collection.update @pending_connection_test[jira_issue_id].jira_doc_id, {$set: {last_webhook_connection_check: new Date(req_body.timestamp)}}
          delete @pending_connection_test[jira_issue_id]
        return

      {fields} = req_body.issue
      {[JustdoJiraIntegration.task_id_custom_field_id]:task_id, [JustdoJiraIntegration.project_id_custom_field_id]:justdo_id} = fields
      if not task_id?
        task = @tasks_collection.findOne({jira_project_id: jira_project_id, jira_issue_id: jira_issue_id}, {fields: {project_id: 1}})
        {_id:task_id, project_id:justdo_id} = task

      if not @isJiraIntegrationInstalledOnJustdo justdo_id
        return

      grid_data = APP.projects._grid_data_com

      jira_project_mountpoint = @getJustdosIdsAndTasksIdsfromMountedJiraProjectId(fields.project.id).task_id

      if (_.find req_body.changelog.items, (item) -> item.field is "issuetype" and item.toString is "Epic")?
        # Move the target task that was changed to epic back to roadmap
        if (parent_task_id = @tasks_collection.findOne({_id: task_id, jira_issue_id: {$ne: null}}, {fields: {parents2: 1}})?.parents2?[0]?.parent)?
          old_path = "/#{parent_task_id}/#{task_id}/"
          grid_data.movePath old_path, {parent: jira_project_mountpoint}, @_getJustdoAdmin justdo_id

      if (changed_issue_parent = _.find req_body.changelog.items, (item) -> item.field in ["IssueParentAssociation", "Parent Issue", "Epic Link"])?
        current_parent_task_id = @tasks_collection.findOne(task_id, {fields: {parents2: 1}}).parents2[0].parent
        old_path = "/#{current_parent_task_id}/#{task_id}/"

        # Change/Add parent
        if (new_parent_issue_id = changed_issue_parent?.to)?
          if (parent_issue = fields.parent)?
            new_parent_issue_id = parseInt parent_issue.id
            new_parent_task_id = @tasks_collection.findOne({project_id: justdo_id, jira_issue_id: new_parent_issue_id}, {fields: {_id: 1}})._id
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
      {[JustdoJiraIntegration.task_id_custom_field_id]:task_id, [JustdoJiraIntegration.project_id_custom_field_id]:justdo_id, issuetype} = req_body.issue.fields
      jira_issue_id = parseInt(req_body.issue.id)
      jira_project_id = parseInt(req_body.issue.fields.project.id)

      removeAllParents = (task_doc) =>
        all_parent_task_ids = _.map task_doc.parents2, (parent_obj) -> parent_obj.parent
        while (parent_task_id = all_parent_task_ids.pop())?
          # removeParent middleware will consume jira_issue_id and ignore this operation
          @deleted_issue_ids.add parseInt(task_doc.jira_issue_id)
          try
            APP.projects._grid_data_com.removeParent "/#{parent_task_id}/#{task_doc._id}/", @_getJustdoAdmin justdo_id
          catch e
            if e.error isnt "unknown-parent"
              all_parent_task_ids.unshift parent_task_id
              console.trace()
              console.error e

      if not @isJiraIntegrationInstalledOnJustdo justdo_id
        return

      # Task deletion from Justdo. Ignore.
      if @deleted_issue_ids.delete jira_issue_id
        return

      # Change parent of all child Task/Story/Bug
      if issuetype.name is "Epic"
        roadmap_task_id = @tasks_collection.findOne({jira_project_id: jira_project_id, jira_mountpoint_type: "roadmap"}, {fields: {_id: 1}})?._id
        query =
          "parents2.parent": task_id
          jira_issue_id:
            $ne: null
          jira_issue_type:
            $in: ["Story", "Task", "Bug"]
        paths_to_move = @tasks_collection.find(query, {fields: {_id: 1}}).map (child_task) -> "/#{task_id}/#{child_task._id}/"

        try
          APP.projects._grid_data_com.movePath paths_to_move, {parent: roadmap_task_id}, @_getJustdoAdmin justdo_id
        catch e
          console.trace()
          console.error e

      # Remove all sub-tasks of the deleted story/task/bug
      if @getIssueTypeRank(issuetype.name, jira_project_id) is 0
        query =
          "parents2.parent": task_id
          jira_issue_id:
            $ne: null
          jira_issue_type:
            $in: _.map @getRankedIssueTypesInJiraProject(jira_project_id)[-1], (issue_type_def) -> issue_type_def.name
        @tasks_collection.find(query, {fields: {jira_issue_id: 1, "parents2.parent": 1}}).forEach (child_task) => removeAllParents child_task

      # At last, remove the issue that was removed in Jira.
      task = @tasks_collection.findOne({jira_issue_id: jira_issue_id}, {fields: {jira_issue_id: 1, "parents2.parent": 1}})
      removeAllParents task

      # Just in case removeParent() fails.
      @tasks_collection.remove task_id

      return
    "jira:version_created": (req_body) -> @_createFixVersionTask req_body
    "jira:version_updated": (req_body) -> @_updateFixVersionTask req_body
    "jira:version_released": (req_body) -> @_updateFixVersionTask req_body
    "jira:version_unreleased": (req_body) -> @_updateFixVersionTask req_body
    "jira:version_deleted": (req_body) -> @_deleteFixVersionTask req_body, true
    # NOTE: IN CASE JIRA ON-PERM IS USED: THE FOLLOWING SPRINT RELATED HANDLERS ONLY SUPPORT SINGLE JIRA INSTANCE
    "sprint_created": (req_body) ->
      sprint = req_body.sprint
      board_id = sprint.originBoardId

      if @isJiraInstanceCloud()
        jira_host = new URL(sprint.self).origin
        client = @getClientByHost(jira_host).agile
      else
        client = _.values(@clients)?[0]?.agile

      if not client?
        throw @_error "client-not-found"

      {err, res} = @pseudoBlockingJiraApiCallInsideFiber "board.getProjects", {boardId: board_id}, client
      if (err = err?.response?.data or err)?
        console.error "[justdo-jira-integration] Fetching project board failed", err
        return

      query =
        $or: []
      ops =
        $addToSet: {}

      _.each res.values, (jira_project) =>
        jira_project_id = parseInt jira_project.id

        tasks_query =
          jira_project_id: jira_project_id
          jira_mountpoint_type: "sprints"
        tasks_options =
          project_id: 1
        if (sprint_mountpiont_task_doc = @tasks_collection.findOne(tasks_query, tasks_options))?
          @_createSprintTask sprint, sprint_mountpiont_task_doc._id, sprint_mountpiont_task_doc.project_id, jira_project_id

        query.$or.push
          "jira_projects.#{jira_project_id}":
            $ne: null
        ops.$addToSet["jira_projects.#{jira_project_id}.sprints"] = sprint

      @jira_collection.update query, ops

      return
    "sprint_updated": (req_body) -> @_updateSprintTask req_body
    "sprint_started": (req_body) -> @_updateSprintTask req_body
    "sprint_closed": (req_body) -> @_deleteSprintTask req_body
    "sprint_deleted": (req_body) -> @_deleteSprintTask req_body
    # NOTE: THE FOLLOWING USERS RELATED HANDLERS ONLY SUPPORT SINGLE JIRA INSTANCE, REGARDLESS OF WHETHER CLOUD OR ON-PERM IS USED
    "user_created": (req_body) -> @_upsertJiraUser req_body, true
    "user_updated": (req_body) -> @_upsertJiraUser req_body
    "user_deleted": (req_body) -> return
