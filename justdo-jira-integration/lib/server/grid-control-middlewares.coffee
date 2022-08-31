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

    isPathUnderJiraTree = (path) =>
      parent_id = GridData.helpers.getPathParentId path
      return @tasks_collection.findOne(_.extend {_id: parent_id}, jira_relevant_task_query, {fields: {_id: 1}})?

    APP.projects._grid_data_com.setGridMethodMiddleware "addParent", (perform_as, etc) ->
      task = etc.item
      new_parent_task = etc.new_parent_item

      if new_parent_task?.jira_sprint_mountpoint_id? or new_parent_task?.jira_fix_version_mountpoint_id?
        # XXX API call to update task/issue's sprint/fix-version
        return true

      # Block attempts to multi-parent under the Jira tree
      if (task.jira_issue_id and new_parent_task?.jira_project_id)
        return

      return true

    APP.projects._grid_data_com.setGridMethodMiddleware "beforeRemoveParent", (path, perform_as, etc) =>
      task_id = GridData.helpers.getPathItemId path
      parent_id = GridData.helpers.getPathParentId path

      query = _.extend {_id: parent_id}, jira_relevant_task_query
      query_options = {fields: jira_relevant_task_fields}

      # The parent isn't under Jira context, ignore.
      if not (parent_task = @tasks_collection.findOne(query, query_options))?
        return true

      # Tasks under these three mountpoint types are hard-coded tasks and thus the parent cannot be removed.
      # XXX Do we want to support removing a sprint/fix-version by deleting the task?
      if parent_task.jira_mountpoint_type in ["root", "sprints", "fix_versions"]
        return

      # In multi-parent scenario, block attempt to remove roadmap parent.
      if parent_task.jira_mountpoint_type is "roadmap" and not etc.no_more_parents
        return

      # Removing a task/issue that's either under roadmap or under another task/issue will delete the task/issue.
      if parent_task.jira_mountpoint_type is "roadmap" or parent_task.jira_issue_id?
        # XXX In Jira if we:
        # XXX - Remove an Epic with childs > childs will become standalone Story/Task/Bug
        # XXX - Remove a Story/Task/Bug > Subtasks will be deleted as well
        # XXX In JustDo we don't allow a task to be removed if it has child tasks, so this code does not handle such situations.
        if (task = @tasks_collection.findOne {_id: task_id, jira_issue_id: {$ne: null}}, {fields: {jira_issue_id: 1, project_id: 1}})?
          @deleted_issue_ids.add task.jira_issue_id
          # XXX In case API returns an error, this code doesn't roll back the action.
          # XXX Consider either to use await or fiber.
          @getJiraClientForJustdo(task.project_id).v2.issues.deleteIssue {issueIdOrKey: task.jira_issue_id}
            .then => @tasks_collection.remove task_id
            .catch (err) -> console.error "[justdo-jira-integration] Failed to remove task/issue #{task_id}", err.response.data
        return true

      if parent_task.jira_sprint_mountpoint_id?
        # XXX Remove issue from sprint
        return true

      if parent_task.jira_fix_version_mountpoint_id?
        # XXX Remove issue from fix version
        return true

      return true

    APP.projects._grid_data_com.setGridMethodMiddleware "beforeMovePath", (path, perform_as, etc) =>
      task_id = GridData.helpers.getPathItemId path
      new_parent_task = etc.new_parent_item

      query = _.extend {_id: task_id}, jira_relevant_task_query
      query_options = {fields: _.extend {jira_issue_type: 1}, jira_relevant_task_fields}

      # Not under Jira context, ignore.
      if not (task = @tasks_collection.findOne query, query_options)?
        return true

      # If the new and old parents are the same, assume reordering is going on and ignore.
      if new_parent_task?._id isnt etc.current_parent_id
        # Block attempts to move hardcoded tasks such as mountpoints/sprints/fix-versions
        if (task.jira_mountpoint_type? and task.jira_mountpoint_type isnt "root") or task.jira_sprint_mountpoint_id? or task.jira_fix_version_mountpoint_id?
          return

        # Block attempt to move tasks directly under these mountpoints as the childs should be auto-generated
        # XXX Do we wish to allow moving path under sprints/fix-versions to create a new sprint/fix-version in Jira?
        if new_parent_task?.jira_mountpoint_type in ["root", "sprints", "fix_versions"]
          return

      # This block specifically handles tasks that are linked to a Jira issue under a mounted tree
      # XXX Move parent-change API-calls from collection hooks to here
      # This block handles the hierachy within Jira issues
      if task.jira_issue_id?
        # Maintain the Epic-[Task/Story/Bug]-Subtask hierarchy.
        if new_parent_task?.jira_issue_id?
          # Epics cannot be under another issue
          if task.jira_issue_type is "Epic"
            return
          # Task/Story/Bug can only be under Epic
          if task.jira_issue_type in ["Story", "Task", "Bug"] and new_parent_task?.jira_issue_type isnt "Epic"
            return
          # Subtasks can only be under Task/Story/Bug
          if task.jira_issue_type in ["Sub-task", "Subtask"] and new_parent_task?.jira_issue_type not in ["Story", "Task", "Bug"]
            return
        # Subtasks cannot be a standalone task/issue under roadmap/sprints/fix-versions as well
        if task.jira_issue_type in ["Sub-task", "Subtask"] and (new_parent_task?.jira_mountpoint_type is "roadmap" or new_parent_task?.jira_sprint_mountpoint_id? or new_parent_task.jira_fix_version_mountpoint_id?)
          return

        if isPathUnderJiraTree path
          # Block attempts to move mounted task/issue outside of the tree
          if not new_parent_task?.jira_project_id?
            return

      return true
