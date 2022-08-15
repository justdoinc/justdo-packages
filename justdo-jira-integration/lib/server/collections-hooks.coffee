Fiber = Npm.require "fibers"

_.extend JustdoJiraIntegration.prototype,
  _setupCollectionsHooks: ->
    @projectsInstallUninstallProcedures()
    @setupJiraHooks()

    return

  projectsInstallUninstallProcedures: ->
    self = @

    self.projects_collection.after.update (user_id, doc, fieldNames, modifier) ->
      feature_id = JustdoJiraIntegration.project_custom_feature_id # shortcut

      if (custom_features = modifier.$set?["conf.custom_features"])?
        previous_custom_features = @previous?.conf?.custom_features
        new_custom_features = doc.conf?.custom_features

        plugin_was_installed_before = false
        if _.isArray previous_custom_features
          plugin_was_installed_before = feature_id in previous_custom_features

        plugin_is_installed_after = false
        if _.isArray new_custom_features
          plugin_is_installed_after = feature_id in new_custom_features

        if not plugin_was_installed_before and plugin_is_installed_after
          self.performInstallProcedures(doc, user_id)

        if plugin_was_installed_before and not plugin_is_installed_after
          self.performUninstallProcedures(doc, user_id)

      return

  setupJiraHooks: ->
    self = @

    # NOTE: When creating tasks using GridData's addChild or addSibling, upsert is called instead of insert.
    # Therefore the before.upsert hook is used.
    self.tasks_collection.before.upsert (user_id, selector, modifier) ->
      # The data inside modifier.$set is identical to the document being inserted inside before/after insert hooks.
      if not (doc = modifier?.$set)?
        return

      if not (task_id = selector?._id)?
        return

      justdo_id = doc.project_id
      jira_server_id = self.getJiraServerInfoFromJustdoId(justdo_id)?.id

      if not self.isJiraIntegrationInstalledOnJustdo justdo_id
        return

      # Created by Jira or during project mount process. Ignore.
      if doc.jira_issue_key or doc.jira_sprint_mountpoint_id or doc.jira_fix_version_mountpoint_id or doc.jira_last_updated
        return

      parent_task_id = doc.parents2[0].parent
      # Only one exists at max, as the parent task cannot be Jira project mountpoint and Jira issue at the same time
      jira_project_key = self.getJiraProjectKeyFromJustdoIdAndMountedTaskId justdo_id, parent_task_id
      parent_task = self.tasks_collection.findOne(parent_task_id, {fields: {jira_issue_key: 1, jira_issue_type: 1, jira_sprint: 1}})

      if not jira_project_key? and not parent_task?.jira_issue_key?
        return

      task_creater_email = Meteor.users.findOne(user_id, {fields: {emails: 1}})?.emails?[0]?.address
      jira_account = await self.getJiraUser justdo_id, {email: task_creater_email}
      jira_account_id = jira_account?[0]?.accountId

      req =
        fields:
          project:
            key: jira_project_key
          summary: doc.title or "#{justdo_id}:#{task_id}"
          issuetype:
            name: "Task"
          [JustdoJiraIntegration.project_id_custom_field_id]: justdo_id
          [JustdoJiraIntegration.task_id_custom_field_id]: task_id
          [JustdoJiraIntegration.last_updated_custom_field_id]: new Date()
      if jira_account_id?
        req.fields.assignee =
          accountId: jira_account_id
        req.fields.reporter =
          accountId: jira_account_id

      # If task is added under a Jira issue, add parent before creating task in Jira
      if (parent_issue_key = parent_task?.jira_issue_key)?
        jira_project_key = parent_issue_key.split("-")[0]
        req.fields.project.key = jira_project_key
        if parent_task.jira_issue_type is "Subtask"
          # XXX Todo: Block the operation. Subtasks can't have child tasks.
          # XXX Or move the newly created task back to jira_project_mountpoint
          jira_project_mountpoint = self.getJustdosIdsAndTasksIdsfromMountedJiraProjectKey(jira_project_key).task_id
        else
          # The behaviour for adding subtask is similar for Jira cloud and Jira server
          if parent_task.jira_issue_type in ["Story", "Task", "Bug"]
            req.fields.issuetype.name = "Sub-task"
            req.fields.parent =
              key: parent_issue_key
          else
            # Jira Cloud
            if self.clients[jira_server_id].v2.config.host.includes "api.atlassian.com"
              req.fields.parent =
                key: parent_issue_key
            # Jira Server
            else
              req.fields[JustdoJiraIntegration.epic_link_custom_field_id] = parent_issue_key

      self.clients[jira_server_id].v2.issues.createIssue req
        .then (res) ->
          if jira_account_id?
            APP.tasks_changelog_manager.logChange
              field: "jira_issue_reporter"
              label: "Issue Reporter"
              change_type: "custom"
              task_id: task_id
              by: user_id
              new_value: "became reporter"

          task_title = "Task ##{res.key.split("-")[1]}"

          summary_update_req =
            issueIdOrKey: res.key
            fields:
              summary: task_title
              [JustdoJiraIntegration.last_updated_custom_field_id]: new Date()

          self.clients[jira_server_id].v2.issues.editIssue summary_update_req
            .catch (err) -> console.error err.response.data

          ops =
            $set:
              title: task_title
              jira_issue_key: res.key
              jira_issue_type: req.fields.issuetype.name
              jira_issue_reporter: user_id
              jira_last_updated: new Date()
          if req.fields.issuetype.name is "Subtask" and not _.isEmpty parent_task.jira_sprint
            ops.$set.jira_sprint = parent_task.jira_sprint
          self.tasks_collection.update task_id, ops
          return
        .catch (e) ->
          console.error e.response.data
      return

    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      justdo_id = doc.project_id
      jira_server_id = self.getJiraServerInfoFromJustdoId(justdo_id)?.id

      if modifier.$set?.jira_last_updated?
        return

      if not self.isJiraIntegrationInstalledOnJustdo justdo_id
        return

      client = self.clients[jira_server_id]

      # Updates toward a specific sprint
      if (jira_sprint_id = doc.jira_sprint_mountpoint_id)? and not _.isEmpty(supported_fields = _.pick modifier.$set, ["start_date", "end_date", "title"])
        {start_date, end_date, title} = supported_fields
        req =
          sprintId: jira_sprint_id
        if start_date?
          req.startDate = start_date
        if end_date?
          req.endDate = end_date
        if title?
          req.name = title

        client.agile.sprint.partiallyUpdateSprint req
        .then (res) -> console.log res
        .catch (err) -> console.error err.response.data
        return

      # Updates toward a specific fix version
      if (jira_fix_version_id = doc.jira_fix_version_mountpoint_id)? and not _.isEmpty(supported_fields = _.pick modifier.$set, ["start_date", "due_date", "title", "description"])
        {start_date, due_date, title, description} = supported_fields
        req =
          id: jira_fix_version_id
        if start_date?
          req.startDate = start_date
        if due_date?
          req.releaseDate = due_date
        if title?
          req.name = title
        if description?
          req.description = description

        client.v2.projectVersions.updateVersion req
        .then (res) -> console.log res
        .catch (err) -> console.error err.response.data
        return

      # Updates toward an issue
      # XXX Try ignore sending back changes from Justdo in Jira's webhook config (likely will involve JQL)
      if (jira_issue_key = doc.jira_issue_key)?
        {fields, transition} = await self._mapJustdoFieldsToJiraFields justdo_id, doc, modifier

        # XXX The statement below handles parent change. Consider putting them into field map.
        if (added_parent_id = modifier.$addToSet?.parents2?.parent)?
          # If parent_issue_key is found, assume Jira parent add/change
          parent_issue_key = self.tasks_collection.findOne(added_parent_id, {fields: {jira_issue_key: 1}})?.jira_issue_key

          # If parent_issue_key isnt found, and the destination task_id is the mountpoint of current Jira project, assume Jira parent removal
          if not parent_issue_key? and (added_parent_id is self.getJustdosIdsAndTasksIdsfromMountedJiraProjectKey(jira_issue_key.split("-")[0]).task_id)
            parent_issue_key = null

          # Send update to jira only when the parent change is within the project mountpoint
          if _.isString(parent_issue_key) or _.isNull(parent_issue_key)
            # Jira Cloud
            if client.v2.config.host.includes "api.atlassian.com"
              fields.parent =
                key: parent_issue_key
            # Jira server
            else
              fields[JustdoJiraIntegration.epic_link_custom_field_id] = parent_issue_key

        if not _.isEmpty fields
          fields[JustdoJiraIntegration.last_updated_custom_field_id] = new Date()

          req =
            issueIdOrKey: jira_issue_key
            fields: fields

          client.v2.issues.editIssue req
            .then (res) -> console.log res
            .catch (err) -> console.error err.response.data
        # Changing state of issue cannot be done with editIssue(); it must be done using doTransition()
        # XXX doTransition() cannot take JustdoJiraIntegration.last_updated_custom_field_id unless manually added to the screen
        # XXX which triggers another update by webhook.
        # XXX Despite it will not cause an infinite loop, it still need to be addressed.
        if not _.isEmpty transition
          req =
            issueIdOrKey: jira_issue_key
            transition: transition

          self.clients[jira_server_id].v2.issues.doTransition req
            .then (res) -> console.log res
            .catch (err) -> console.error err.response.data

        return

      return

    self.tasks_collection.before.remove (user_id, doc) ->
      justdo_id = doc.project_id
      jira_server_id = self.getJiraServerInfoFromJustdoId(justdo_id)?.id

      if not self.isJiraIntegrationInstalledOnJustdo justdo_id
        return

      jira_issue_key = doc.jira_issue_key
      if not jira_issue_key?
        return
      self.deleted_issue_keys.add jira_issue_key
      self.getJiraClientForJustdo(doc.project_id).v2.issues.deleteIssue {issueIdOrKey: jira_issue_key}
        .then (res) -> console.log res
        .catch (err) -> console.error err.response.data

      return

    return
