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

      # Created by Jira or during project mount process. Ignore.
      if doc.jira_issue_id or doc.jira_sprint_mountpoint_id or doc.jira_fix_version_mountpoint_id or doc.jira_last_updated
        return

      justdo_id = doc.project_id

      if not self.isJiraIntegrationInstalledOnJustdo justdo_id
        return

      jira_server_id = self.getJiraServerInfoFromJustdoId(justdo_id)?.id

      # XXX Multi-parent situation is NOT handled yet!
      parent_task_id = doc.parents2[0].parent
      parent_task = self.tasks_collection.findOne(parent_task_id, {fields: {jira_issue_id: 1, jira_project_id: 1, jira_issue_type: 1, jira_sprint: 1}})

      # If jira_project_id doesn't exist, assume the task is created outside of mountpoint.
      if not (jira_project_id = parent_task?.jira_project_id)?
        return

      task_creater_email = Meteor.users.findOne(user_id, {fields: {emails: 1}})?.emails?[0]?.address
      jira_account = await self.getJiraUser justdo_id, {email: task_creater_email}
      jira_account_id = jira_account?[0]?.accountId

      req =
        fields:
          project:
            id: jira_project_id
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
      if (parent_issue_id = parent_task?.jira_issue_id)?
        if parent_task.jira_issue_type is "Subtask"
          # XXX Todo: Block the operation. Subtasks can't have child tasks.
          # XXX Or move the newly created task back to jira_project_mountpoint
          console.log "The issue is created under a subtask and is forbidden."
        else
          # The behaviour for adding subtask is similar for Jira cloud and Jira server
          # XXX Custom issue type is not handled
          if parent_task.jira_issue_type in ["Story", "Task", "Bug"]
            req.fields.issuetype.name = "Sub-task"
            req.fields.parent =
              id: "#{parent_issue_id}"
          else
            # Jira Cloud
            if self.clients[jira_server_id].v2.config.host.includes "api.atlassian.com"
              req.fields.parent =
                id: "#{parent_issue_id}"
            # Jira Server
            else
              req.fields[JustdoJiraIntegration.epic_link_custom_field_id] = "#{parent_issue_id}"

      self.clients[jira_server_id].v2.issues.createIssue req
        .then (res) ->
          # Log reporter change only if the user created this task is also a Jira user (detected by email).
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
            issueIdOrKey: res.id
            fields:
              summary: task_title
              [JustdoJiraIntegration.last_updated_custom_field_id]: new Date()

          self.clients[jira_server_id].v2.issues.editIssue summary_update_req
            .catch (err) -> console.error err.response.data

          ops =
            $set:
              title: task_title
              jira_issue_key: res.key
              jira_issue_id: res.id
              jira_project_id: req.fields.project.id
              jira_issue_type: req.fields.issuetype.name
              jira_issue_reporter: user_id
              jira_last_updated: new Date()

          # A subtask will always have the same sprint as its parent.
          # addParent() is not necessary as the parent task should already be under the correct sprint parent.
          if req.fields.issuetype.name is "Subtask" and not _.isEmpty parent_task.jira_sprint
            ops.$set.jira_sprint = parent_task.jira_sprint

          self.tasks_collection.update task_id, ops
          return
        .catch (e) ->
          console.error e.response.data
      return

    # NOTE: This hook is solely for changing the modifier.
    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      # Hardcoded mountpoint tasks has fixed title and cannot be changed (except for the root mountpoint).
      if doc.jira_mountpoint_type? and doc.jira_mountpoint_type isnt "root" and modifier?.$set?.title?
        delete modifier.$set.title

      # Issues must have an issuetype
      if doc?.jira_issue_id? or modifier?.$set?.jira_issue_id?
        # Client side $unset operations will be translated to $set: {[field]: null}
        # Hence there're two conditions
        if _.isNull modifier?.$set?.jira_issue_type
          delete modifier.$set.jira_issue_type
        if modifier?.$unset?.jira_issue_type?
          delete modifier.$unset.jira_issue_type
      else
        # Only issues can have issuetype
        # * All other Jira fields are not handled as they are not editable on the grid.
        if modifier?.$set?.jira_issue_type?
          delete modifier.$set.jira_issue_type
      return

    # NOTE: As this hook contains async function calls, this hook is async and changing the modifier will NOT have any effect.
    # If you wish to change the modifier, use the hook above.
    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      justdo_id = doc.project_id

      if modifier.$set?.jira_last_updated?
        return

      if not self.isJiraIntegrationInstalledOnJustdo justdo_id
        return

      jira_server_id = self.getJiraServerInfoFromJustdoId(justdo_id)?.id
      client = self.clients[jira_server_id]

      # Updates toward an issue
      # XXX Try ignore sending back changes from Justdo in Jira's webhook config (likely will involve JQL)
      if (jira_issue_id = doc.jira_issue_id)?
        {fields, transition} = await self._mapJustdoFieldsToJiraFields justdo_id, doc, modifier

        # XXX The statement below handles parent change. Consider putting them into field map.
        # XXX multi-parent is NOT handled!
        if (added_parent_id = modifier.$addToSet?.parents2?.parent)?
          # If parent_issue_id is found, assume Jira parent add/change
          parent_task = self.tasks_collection.findOne(added_parent_id, {fields: {jira_issue_id: 1, jira_mountpoint_type: 1}})
          if (parent_issue_id = parent_task?.jira_issue_id)?
            # If parent_issue_id isnt found, and the destination task_id is the mountpoint of current Jira project, assume Jira parent removal
            if not parent_issue_id? and parent_task.jira_mountpoint_type is "roadmap"
              parent_issue_id = null

            # Send update to jira only when the parent change is within the project mountpoint
            if parent_issue_id? or _.isNull(parent_issue_id)
              if _.isNumber parent_issue_id
                parent_issue_id = "#{parent_issue_id}"
              # Jira Cloud
              if client.v2.config.host.includes "api.atlassian.com"
                fields.parent =
                  id: parent_issue_id
              # Jira server
              else
                fields[JustdoJiraIntegration.epic_link_custom_field_id] = parent_issue_id

        if not _.isEmpty fields
          fields[JustdoJiraIntegration.last_updated_custom_field_id] = new Date()

          req =
            issueIdOrKey: jira_issue_id
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
            issueIdOrKey: jira_issue_id
            transition: transition

          self.clients[jira_server_id].v2.issues.doTransition req
            .then (res) -> console.log res
            .catch (err) -> console.error err.response.data

        return

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

      return

    return
