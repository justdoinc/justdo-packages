_.extend JustdoJiraIntegration.prototype,
  _setupGridMiddlewares: ->
    jira_relevant_task_query =
      jira_project_id:
        $ne: null
      $or: [
        jira_issue_id:
          $ne: null
      ,
        jira_mountpoint_type:
          $ne: null
      ,
        jira_sprint_mountpoint_id:
          $ne: null
      ,
        jira_fix_version_mountpoint_id:
          $ne: null
      ]
    jira_relevant_task_fields =
      jira_mountpoint_type: 1
      jira_sprint_mountpoint_id: 1
      jira_fix_version_mountpoint_id: 1
      jira_project_id: 1
      jira_issue_id: 1

    getParentDocIfPathIsUnderJiraTree = (path) =>
      parent_id = GridData.helpers.getPathParentId path
      query = _.extend {_id: parent_id}, jira_relevant_task_query
      return @tasks_collection.findOne(query, {fields: jira_relevant_task_fields})

    APP.projects._grid_data_com.setGridMethodMiddleware "addChild", (path, new_item, perform_as) =>
      query = _.extend {_id: GridData.helpers.getPathItemId path}, jira_relevant_task_query
      if not (parent_task = @tasks_collection.findOne query, {fields: jira_relevant_task_fields})?
        return true

      # Root mountpoint should only contain roadmap/sprint-mountpoint/fix-version-mountpoint
      if parent_task?.jira_mountpoint_type is "root" and not new_item?.jira_mountpoint_type?
        return

      # Sprints mountpoint should only contain individual sprints
      # XXX Do we want to allow creating a new sprint by adding child?
      if parent_task?.jira_mountpoint_type is "sprints" and not new_item?.jira_sprint_mountpoint_id?
        return

      # Fix-version mountpoint should only contain individual fix-versions
      # XXX Do we want to allow creating a fix-version by adding child?
      if parent_task?.jira_mountpoint_type is "fix_versions" and not new_item?.jira_fix_version_mountpoint_id?
        return

      # Block attempts to add child directly under individual sprint/fix-version.
      # XXX Do we want to allow creating task under sprint/fix-version directly?
      if parent_task?.jira_sprint_mountpoint_id? or parent_task?.jira_fix_version_mountpoint_id?
        return

      return true

    APP.projects._grid_data_com.setGridMethodMiddleware "addParent", (perform_as, etc) =>
      task = etc.item
      new_parent_task = etc.new_parent_item

      if (jira_issue_id = task.jira_issue_id)?
        # Block attempts to multi-parent a Jira task under another Jira task or hardcoded mountpoints.
        if new_parent_task?.jira_mountpoint_type?
          return

        # Assign issue to sprint
        if (sprint_id = new_parent_task?.jira_sprint_mountpoint_id)?
          existing_task_parents = _.keys task.parents
          if (existing_sprint_parent = @tasks_collection.findOne({_id: {$in: existing_task_parents}, jira_sprint_mountpoint_id: {$ne: null}}, {fields: {jira_sprint_mountpoint_id: 1}}))?
            @removed_sprint_parent_issue_pairs.add "#{task._id}:#{existing_sprint_parent.jira_sprint_mountpoint_id}"
          @assignIssueToSprint jira_issue_id, sprint_id, task.project_id
          return true

        # Assign issue to fix version
        if (fix_version_id = new_parent_task?.jira_fix_version_mountpoint_id)?
          @updateIssueFixVersion jira_issue_id, {add: fix_version_id}, task.project_id
          return true
      else
        # Block attempts for non-Jira tasks to be added inside a Jira tree
        # XXX Do we want to allow adding roadmap as parent of an existing tree and convert the entire tree into Jira issues?
        if new_parent_task?.jira_project_id?
          return

      return true

    APP.projects._grid_data_com.setGridMethodMiddleware "beforeRemoveParent", (path, perform_as, etc) =>
      task_id = GridData.helpers.getPathItemId path
      parent_id = GridData.helpers.getPathParentId path

      query = _.extend {_id: parent_id}, jira_relevant_task_query
      query_options = {fields: jira_relevant_task_fields}

      # Task is not a Jira issue. Ignore.
      if not (task = @tasks_collection.findOne {_id: task_id, jira_issue_id: {$ne: null}}, {fields: {jira_issue_id: 1, project_id: 1}})?
        return true

      # Task is removed from Jira. Ignore.
      if @deleted_issue_ids.delete parseInt(task.jira_issue_id)
        return true

      # The parent isn't under Jira context, ignore.
      if not (parent_task = @tasks_collection.findOne(query, query_options))?
        return true

      # Tasks under these three mountpoint types are hard-coded tasks and thus the parent cannot be removed.
      # XXX Do we want to support removing a sprint/fix-version by deleting the task?
      if parent_task.jira_mountpoint_type in ["root", "sprints", "fix_versions"]
        return

      # Removing a task/issue that's either under roadmap or under another task/issue will delete the task/issue.
      if parent_task.jira_mountpoint_type is "roadmap" or parent_task.jira_issue_id?
        # In multi-parent scenario, block attempt to remove roadmap/issue parent.
        if not etc.no_more_parents
          return

        # XXX In Jira if we:
        # XXX - Remove an Epic with childs > childs will become standalone Story/Task/Bug
        # XXX - Remove a Story/Task/Bug > Subtasks will be deleted as well
        # XXX In JustDo we don't allow a task to be removed if it has child tasks, so this code does not handle such situations.
        @deleted_issue_ids.add task.jira_issue_id
        # XXX In case API returns an error, this code doesn't roll back the action.
        # XXX Consider either to use await or fiber.
        @getJiraClientForJustdo(task.project_id).v2.issues.deleteIssue {issueIdOrKey: task.jira_issue_id}
          .then => @tasks_collection.remove task_id
          .catch (err) -> console.error "[justdo-jira-integration] Failed to remove task/issue #{task_id}", err.response.data
        return true

      if parent_task?.jira_sprint_mountpoint_id?
        # If "task_id:sprint_id" is found in removed_sprint_parent_issue_pairs,
        # it means this action is originated from our side using addParent() to change an issue's sprint.
        # In this case we don't have to call moveIssuesToBacklog(), or it will remove the sprint of the issue completely.
        if not @removed_sprint_parent_issue_pairs.delete("#{task_id}:#{parent_task.jira_sprint_mountpoint_id}")
          client = @getJiraClientForJustdo(task.project_id).agile
          client.backlog.moveIssuesToBacklog {issues: ["#{task.jira_issue_id}"]}
            .catch (err) -> console.error "[justdo-jira-integration] Remove issue sprint failed", err.response.data
        return true

      if (fix_version_id = parent_task?.jira_fix_version_mountpoint_id)?
        @updateIssueFixVersion task.jira_issue_id, {remove: fix_version_id}, task.project_id
        return true

      return true

    APP.projects._grid_data_com.setGridMethodMiddleware "beforeMovePath", (path, perform_as, etc) =>
      task_id = GridData.helpers.getPathItemId path
      new_parent_task = etc.new_parent_item

      # If the new and old parents are the same, assume reordering is performed and ignore.
      if new_parent_task?._id is etc.current_parent_id
        return true

      # Block attempt to move tasks directly under these mountpoints as the childs should be auto-generated,
      # and individual sprints/fix-versions (addParent() should be used to assign an issue to sprint/fix-version).
      # XXX Do we wish to allow moving path under sprints/fix-versions to create a new sprint/fix-version in Jira?
      if new_parent_task?.jira_mountpoint_type in ["root", "sprints", "fix_versions"]
        return

      query = _.extend {_id: task_id}, jira_relevant_task_query
      query_options = {fields: _.extend {jira_issue_type: 1, project_id: 1}, jira_relevant_task_fields}
      # Ignore non-Jira tasks, except if the new parent is under Jira context.
      if not (task = @tasks_collection.findOne query, query_options)?
        if new_parent_task?.jira_project_id?
          return
        return true

      # Block attempts to move hardcoded tasks such as mountpoints/sprints/fix-versions
      if (task.jira_mountpoint_type? and task.jira_mountpoint_type isnt "root") or task.jira_sprint_mountpoint_id? or task.jira_fix_version_mountpoint_id?
        return

      # This block specifically handles tasks that are linked to a Jira issue under a mounted tree
      # XXX Move parent-change API-calls from collection hooks to here
      # This block handles the hierachy within Jira issues
      if (jira_issue_id = task.jira_issue_id)?
        # Maintain the Epic-[Task/Story/Bug]-Subtask hierarchy.
        if new_parent_task?.jira_issue_id?
          # Epics cannot be under another issue
          if task.jira_issue_type is "Epic"
            return
          # Task/Story/Bug can only be under Epic
          if task.jira_issue_type in ["Story", "Task", "Bug"] and new_parent_task?.jira_issue_type isnt "Epic"
            return
        # Subtasks has some additional constraints and ops
        if task.jira_issue_type in ["Sub-task", "Subtask"]
          # Subtasks can only be under Task/Story/Bug
          if new_parent_task?.jira_issue_type not in ["Story", "Task", "Bug"]
            return
          # Update sprint of subtask to be the same as its new parent
          parent_jira_sprint_name = new_parent_task?.jira_sprint
          @tasks_collection.update task._id, {$set: {jira_sprint: parent_jira_sprint_name or null}}

        if (old_parent_task = getParentDocIfPathIsUnderJiraTree path)?
          # Block attempts to move mounted task/issue outside of the tree
          if not new_parent_task?.jira_project_id?
            return

          # Change sprint for issue
          if old_parent_task.jira_sprint_mountpoint_id? and (new_sprint_id = new_parent_task?.jira_sprint_mountpoint_id)?
            @assignIssueToSprint jira_issue_id, new_sprint_id, task.project_id
            return true

          # Change fix versions for issue
          if (old_fix_version_id = old_parent_task.jira_fix_version_mountpoint_id)? and (new_fix_version_id = new_parent_task?.jira_fix_version_mountpoint_id)?
            @updateIssueFixVersion jira_issue_id, {remove: old_fix_version_id, add: new_fix_version_id}, task.project_id
            return true

      return true
