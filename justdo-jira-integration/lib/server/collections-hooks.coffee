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

      parent_task_id = doc.parents2[0].parent
      parent_task = self.tasks_collection.findOne(parent_task_id, {fields: {jira_issue_id: 1, jira_issue_key: 1, jira_project_id: 1, jira_issue_type: 1, jira_sprint: 1, jira_mountpoint_type: 1}})

      # If jira_project_id doesn't exist, assume the task is created outside of mountpoint.
      if not (jira_project_id = parent_task?.jira_project_id)?
        return

      if not (jira_server_id = self.getJiraServerInfoFromJustdoId(justdo_id)?.id)?
        return

      client = self.clients[jira_server_id]

      # Create a new fix version
      if parent_task?.jira_mountpoint_type is "fix_versions"
        {err, res} = self.pseudoBlockingJiraApiCallInsideFiber "projectVersions.createVersion", {projectId: parent_task.jira_project_id, name: "New Version"}, client.v2
        if err?
          throw self._error "jira-update-failed", "Failed to create new fix version", err

        task_fields =
          title: res.name
          jira_project_id: parseInt res.projectId
          jira_fix_version_mountpoint_id: parseInt res.id
          jira_last_updated: new Date()

        _.extend modifier.$set, task_fields

        return

      # Create a new sprint
      if parent_task?.jira_mountpoint_type is "sprints"
        # XXX We currently don't support specifying board when creating sprint. The first board we got from this API is used.
        res = self.getAllBoardsAssociatedToJiraProject jira_project_id, {client: client.agile}
        if not (board_id = res?.values?[0]?.id)?
          throw self._error "jira-update-failed", "Failed to obtain board id when creating new sprint"

        {err, res} = self.pseudoBlockingJiraApiCallInsideFiber "sprint.createSprint", {originBoardId: board_id, name: "New Sprint"}, client.agile
        if err?
          throw self._error "jira-update-failed", "Failed to create new sprint", err

        task_fields =
          title: res.name
          jira_project_id: jira_project_id
          jira_sprint_mountpoint_id: parseInt res.id
          jira_last_updated: new Date()

        _.extend modifier.$set, task_fields

        return

      # Create a new issue
      task_creater_email = Meteor.users.findOne(user_id, {fields: {emails: 1}})?.emails?[0]?.address
      jira_account = self.getJiraUser justdo_id, {email: task_creater_email}
      jira_account_id_or_name = jira_account?[0]?.accountId or jira_account?[0]?.name
      jira_doc_id = self.jira_collection.findOne({"server_info.id": jira_server_id}, {fields: {_id: 1}})?._id

      default_issue_type_name = self.getRankedIssueTypesInJiraProject(jira_doc_id, jira_project_id)?[0]?[0]?.name or "Story"

      req =
        fields:
          project:
            id: jira_project_id
          summary: doc.title or "#{justdo_id}:#{task_id}"
          issuetype:
            # the first [0] is the issue type rank, in our case it's the same level as Task/Bug/Story.
            # the second [0] is to get the first issue type under rank 0
            name: default_issue_type_name
          [JustdoJiraIntegration.project_id_custom_field_id]: justdo_id
          [JustdoJiraIntegration.task_id_custom_field_id]: task_id
          [JustdoJiraIntegration.last_updated_custom_field_id]: new Date()
      if jira_account_id_or_name?
        if self.isJiraInstanceCloud()
          req.fields.assignee =
            accountId: jira_account_id_or_name
          req.fields.reporter =
            accountId: jira_account_id_or_name
        else
          req.fields.assignee =
            name: jira_account_id_or_name
          req.fields.reporter =
            name: jira_account_id_or_name

      # If task is added under a Jira issue, add parent before creating task in Jira
      if (parent_issue_id = parent_task?.jira_issue_id)?
        # The behaviour for adding subtask is similar for Jira cloud and Jira server
        if self.getIssueTypeRank(parent_task?.jira_issue_type, parent_task?.jira_project_id) is 0
          req.fields.issuetype.name = "Sub-task"
          req.fields.parent =
            id: "#{parent_issue_id}"
        else
          # Jira Cloud
          if self.isJiraInstanceCloud()
            req.fields.parent =
              id: "#{parent_issue_id}"
          # Jira Server
          else
            req.fields[JustdoJiraIntegration.epic_link_custom_field_id] = "#{parent_task.jira_issue_key}"

      # Get create issue metadata from Jira to add all required fields by using a default value
      create_issue_meta_req =
        issuetypeNames: default_issue_type_name
        projectIds: jira_project_id
        expand: "projects.issuetypes.fields"
      {err, res} = self.pseudoBlockingJiraApiCallInsideFiber("issues.getCreateIssueMeta", create_issue_meta_req, client.v2)
      if (create_issue_meta_fields = res.projects?[0]?.issuetypes?[0]?.fields)?
        for field_id, field_def of create_issue_meta_fields
          # Only add those that are required, doesn't have default value, and not already inside req.
          if field_def.required and (not field_def.hasDefaultValue) and not _.has req.fields, field_id
            field_type = field_def.schema?.type
            default_field_val = null

            if _.isEmpty field_def.allowedValues
              if field_type in ["date", "datetime"]
                default_field_val = new Date()
              else if field_type is "number"
                default_field_val = 0
              else
                default_field_val = "Default #{field_def.name} Value"
            else
              default_field_val = {id: field_def.allowedValues[0].id}
              if field_type is "array"
                default_field_val = [default_field_val]

            req.fields[field_id] = default_field_val

      {err, res} = self.pseudoBlockingJiraApiCallInsideFiber "issues.createIssue", req, client.v2
      if err?
        throw self._error "jira-update-failed", "Failed to create issue.", err

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
        notifyUsers: false
        fields:
          summary: task_title
          [JustdoJiraIntegration.last_updated_custom_field_id]: new Date()

      {err} = self.pseudoBlockingJiraApiCallInsideFiber "issues.editIssue", summary_update_req, client.v2
      if err?
        throw self._error "jira-update-failed", "Failed to create issue.", err

      task_fields =
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
        task_fields.jira_sprint = parent_task.jira_sprint

      _.extend modifier.$set, task_fields

      return

    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      justdo_id = doc.project_id

      if modifier.$set?.jira_last_updated?
        return

      if not self.isJiraIntegrationInstalledOnJustdo justdo_id
        return

      if not (jira_server_id = self.getJiraServerInfoFromJustdoId(justdo_id)?.id)?
        return

      client = self.clients[jira_server_id]

      # Hardcoded mountpoint tasks has fixed title and cannot be changed (except for the root mountpoint).
      if doc.jira_mountpoint_type? and doc.jira_mountpoint_type isnt "root" and modifier?.$set?.title?
        delete modifier.$set.title
        return

      # Updates toward an issue
      # XXX Try ignore sending back changes from Justdo in Jira's webhook config (likely will involve JQL)
      if (jira_issue_id = doc.jira_issue_id)?
        # Client side $unset operations will be translated to $set: {[field]: null}
        # Hence there're two conditions
        if _.isNull modifier?.$set?.jira_issue_type
          delete modifier.$set.jira_issue_type
        if modifier?.$unset?.jira_issue_type?
          delete modifier.$unset.jira_issue_type

        {fields, transition} = self._mapJustdoFieldsToJiraFields justdo_id, doc, modifier

        # XXX The statement below handles parent change. Consider putting them into field map.
        if (added_parent_id = modifier.$addToSet?.parents2?.parent)?
          # If parent_issue_id is found, assume Jira parent add/change/remove
          parent_task = self.tasks_collection.findOne(added_parent_id, {fields: {jira_issue_id: 1, jira_issue_key: 1, jira_issue_type: 1, jira_project_id: 1, jira_mountpoint_type: 1}})

          if (parent_issue_id = parent_task?.jira_issue_id)? or (parent_task.jira_mountpoint_type is "roadmap")
            # If parent_issue_id isnt found and the destination task_id is the mountpoint of current Jira project, assume Jira parent removal
            if not parent_issue_id?
              parent_issue_id = null

            # Send update to jira only when the parent change is within the project mountpoint
            if parent_issue_id? or _.isNull(parent_issue_id)
              if _.isNumber parent_issue_id
                parent_issue_id = "#{parent_issue_id}"

              if self.getAuthTypeIfJiraInstanceIsOnPerm()?
                # Jira Server accepts issue key only when assigning parent, and does not support changing parent of a subtask.
                if (_.isNull parent_issue_id) or (@getIssueTypeRank(parent_task?.jira_issue_type, parent_task?.jira_project_id) is 1)
                  fields[JustdoJiraIntegration.epic_link_custom_field_id] = parent_task?.jira_issue_key or null
                fields.parent =
                  key: parent_task?.jira_issue_key or null
              else
                fields.parent =
                  id: parent_issue_id

        if not _.isEmpty fields
          fields[JustdoJiraIntegration.last_updated_custom_field_id] = new Date()

          req =
            issueIdOrKey: jira_issue_id
            notifyUsers: false
            fields: fields

          {err} = self.pseudoBlockingJiraApiCallInsideFiber "issues.editIssue", req, client.v2
          if err?
            throw self._error "jira-update-failed", "Failed to edit #{doc.jira_issue_key}.", err

        # Changing state of issue cannot be done with editIssue(); it must be done using doTransition()
        # XXX doTransition() cannot take JustdoJiraIntegration.last_updated_custom_field_id unless manually added to the screen
        # XXX which triggers another update by webhook.
        # XXX Despite it will not cause an infinite loop, it still need to be addressed.
        if not _.isEmpty transition
          req =
            issueIdOrKey: jira_issue_id
            transition: transition

          {err} = self.pseudoBlockingJiraApiCallInsideFiber "issues.doTransition", req, client.v2
          if err?
            throw self._error "jira-update-failed", "Failed to transition #{doc.jira_issue_key}.", err

        return
      else
        # Only issues can have issuetype
        # * All other Jira fields are not handled as they are not editable on the grid.
        if modifier?.$set?.jira_issue_type?
          delete modifier.$set.jira_issue_type

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

        {err} = self.pseudoBlockingJiraApiCallInsideFiber "sprint.partiallyUpdateSprint", req, client.agile
        if err?
          throw self._error "jira-update-failed", "Failed to update #{doc.title}.", err

        return

      # Updates toward a specific fix version
      if (jira_fix_version_id = doc.jira_fix_version_mountpoint_id)? and not _.isEmpty(supported_fields = _.pick modifier.$set, ["start_date", "due_date", "title", "description"])
        req =
          id: jira_fix_version_id

        if _.has supported_fields, "start_date"
          req.startDate = supported_fields.start_date
        if _.has supported_fields, "due_date"
          req.releaseDate = supported_fields.due_date
        if _.has supported_fields, "title"
          req.name = supported_fields.title
        if _.has supported_fields, "description"
          req.description = supported_fields.description

        {err} = self.pseudoBlockingJiraApiCallInsideFiber "projectVersions.updateVersion", req, client.v2
        if err?
          throw self._error "jira-update-failed", "Failed to update #{doc.title}.", err

        return

      return

    self.projects_collection.after.update (user_id, doc, field_names, modifier, options) ->
      if not (jira_doc_id = doc.conf?["justdo_jira:id"])?
        return

      # When new member is added, replace proxy Jira user with the actual member and update jira_doc's jira_users email record.
      # The reason we do this in project collection instead of users collection is that it's costly to go over all existing users
      if (members_modifier = modifier?.$push?.members)?
        jira_server_id = self.jira_collection.findOne(jira_doc_id, {fields: {"server_info.id": 1}}).server_info?.id
        if not (client = self.clients[jira_server_id])?
          return

        if members_modifier.$each?
          added_member_ids = _.map members_modifier.$each, (added_member) -> added_member.user_id
        else
          added_member_ids = [members_modifier.user_id]

        # For all added_members_emails, exclude the proxy emails, and the emails that're already linked
        added_members_emails = Meteor.users.find({_id: {$in: added_member_ids}}, {fields: {"emails.address": 1}}).map (user) -> user.emails?[0]?.address
        added_members_emails = new Set added_members_emails
        if (jira_users = self.jira_collection.findOne(jira_doc_id, {fields: {"jira_users.email": 1, "jira_users.is_proxy": 1}})?.jira_users)?
          emails_to_exclude = []
          for jira_user in jira_users
            if jira_user.is_proxy or added_members_emails.has jira_user.email
              emails_to_exclude.push jira_user.email
          added_members_emails = _.without Array.from(added_members_emails), ...emails_to_exclude

        # Do nothing if added_members_emails is empty after sanitizing.
        if _.isEmpty added_members_emails
          return

        for email in added_members_emails
          client.v2.userSearch.findUsers {query: email}
            .then (res) ->
              if _.isEmpty res
                return
              jira_account_id = res[0].accountId

              query =
                _id: jira_doc_id
                jira_users:
                  $elemMatch:
                    jira_account_id: jira_account_id
                    is_proxy: true
              query_options =
                fields:
                  "jira_users.$": 1
              if (user_to_update = self.jira_collection.findOne(query, query_options)?.jira_users?[0])?
                proxy_user_id = APP.accounts.getUserByEmail(user_to_update.email)._id
                actual_user_id = APP.accounts.getUserByEmail(email)._id

                # Update jira_users array of jira_doc
                ops =
                  $set:
                    "jira_users.$.email": email
                  $unset:
                    "jira_users.$.is_proxy": 1
                self.jira_collection.update query, ops

                # Replace project proxy user with actual user
                justdo_id = doc._id

                if not _.find(doc.members, (member) -> member.user_id is actual_user_id)?
                  APP.projects.inviteMember justdo_id, {email}

                # Remove proxy user from justdo
                APP.projects.removeMember justdo_id, proxy_user_id, proxy_user_id

                # Replace task member
                root_items = self.tasks_collection.find({project_id: justdo_id, jira_project_id: {$ne: null}, users: proxy_user_id, jira_mountpoint_type: "root"}, {fields: {_id: 1}}).map (task_doc) -> task_doc._id
                tasks_to_add_members = []
                tasks_to_transfer_ownership = []
                self.tasks_collection.find({project_id: justdo_id, jira_project_id: {$ne: null}, users: proxy_user_id}, {fields: {_id: 1, owner_id: 1}})
                  .forEach (task_doc) ->
                    task_id = task_doc._id
                    tasks_to_add_members.push task_id
                    if task_doc.owner_id is proxy_user_id
                      tasks_to_transfer_ownership.push task_id
                    return

                # Updates task users
                if not _.isEmpty tasks_to_add_members
                  APP.projects.bulkUpdateTasksUsers justdo_id,
                    tasks: tasks_to_add_members
                    members_to_add: [actual_user_id]
                    members_to_remove: [proxy_user_id]
                    user_perspective_root_items: root_items
                    items_to_assume_ownership_of: tasks_to_transfer_ownership
                  , actual_user_id

                return

              return
            .catch (err) -> console.error err
      return

    return
