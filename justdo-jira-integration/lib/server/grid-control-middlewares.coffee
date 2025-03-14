_.extend JustdoJiraIntegration.prototype,
  _setupGridMiddlewares: ->
    jira_relevant_task_query =
      jira_project_id:
        $ne: null

    jira_relevant_task_fields =
      jira_mountpoint_type: 1
      jira_sprint_mountpoint_id: 1
      jira_fix_version_mountpoint_id: 1
      jira_project_id: 1
      jira_issue_id: 1
      project_id: 1
      title: 1

    getParentDocIfPathIsUnderJiraTree = (path) =>
      parent_id = GridData.helpers.getPathParentId path
      query = _.extend {_id: parent_id}, jira_relevant_task_query
      return @tasks_collection.findOne(query, {fields: jira_relevant_task_fields})

    APP.projects._grid_data_com.setGridMethodMiddleware "addChild", (path, new_item, perform_as) =>
      query = _.extend {_id: GridData.helpers.getPathItemId path}, jira_relevant_task_query
      if not (parent_task = @tasks_collection.findOne query, {fields: _.extend({jira_issue_type: 1}, jira_relevant_task_fields)})?
        return true

      # Root mountpoint should only contain roadmap/sprint-mountpoint/fix-version-mountpoint
      if parent_task?.jira_mountpoint_type is "root" and not new_item?.jira_mountpoint_type?
        throw @_error "jira-update-failed", "You can only create new issues under roadmap."

      # Block attempts to add child directly under individual sprint/fix-version.
      # XXX Do we want to allow creating task under sprint/fix-version directly?
      if parent_task?.jira_sprint_mountpoint_id? or parent_task?.jira_fix_version_mountpoint_id?
        throw @_error "jira-update-failed", "Cannot create task directly under a sprint/fix-version.<br>To assign a task to a sprint/fix-version, add the target sprint/fix-version as the task's parent."

      # Subtasks cannot be parents
      if @getIssueTypeRank(parent_task?.jira_issue_type, parent_task?.jira_project_id) is -1
        throw @_error "jira-update-failed", "Subtasks cannot have subtasks."

      return true

    APP.projects._grid_data_com.setGridMethodMiddleware "addParent", (perform_as, etc) =>
      task = etc.item
      new_parent_task = etc.new_parent_item

      if not (jira_issue_id = task.jira_issue_id)?
        # Block attempts for non-Jira tasks to be added inside a Jira tree
        # XXX Do we want to allow adding roadmap as parent of an existing tree and convert the entire tree into Jira issues?
        if new_parent_task?.jira_project_id?
          throw @_error "jira-update-failed", "You can't put it here."
        return true

      # Block attempts to multi-parent a Jira task under another Jira task or hardcoded mountpoints.
      if new_parent_task?.jira_mountpoint_type?
        throw @_error "jira-update-failed", "You can't put it here."

      if new_parent_task?.jira_issue_type?
        throw @_error "jira-update-failed", "You cannot multi-parent an issue under another issue. To add issue parent, drag the task under the new parent instead."

      # Assign issue to sprint
      if (sprint_id = new_parent_task?.jira_sprint_mountpoint_id)?
        existing_task_parents = _.keys task.parents
        if (existing_sprint_parent = @tasks_collection.findOne({_id: {$in: existing_task_parents}, jira_sprint_mountpoint_id: {$ne: null}}, {fields: {jira_sprint_mountpoint_id: 1}}))?
          @removed_sprint_parent_issue_pairs.add "#{task._id}:#{existing_sprint_parent.jira_sprint_mountpoint_id}"
        return @assignIssueToSprint jira_issue_id, sprint_id, task.project_id

      # Assign issue to fix version
      if (fix_version_id = new_parent_task?.jira_fix_version_mountpoint_id)?
        return @updateIssueFixVersion jira_issue_id, {add: fix_version_id}, task.project_id

      return true

    APP.projects._grid_data_com.setGridMethodMiddleware "beforeRemoveParent", (path, perform_as, etc) =>
      task_id = GridData.helpers.getPathItemId path
      parent_id = GridData.helpers.getPathParentId path

      query = _.extend {_id: parent_id}, jira_relevant_task_query
      query_options = {fields: jira_relevant_task_fields}

      # Task is not related to Jira. Ignore.
      if not (task = @tasks_collection.findOne {_id: task_id, jira_project_id: {$ne: null}}, {fields: jira_relevant_task_fields})?
        return true

      # Task is removed from Jira. Ignore.
      if @deleted_issue_ids.delete parseInt(task.jira_issue_id)
        return true

      # Sprint is removed from Jira. Ignore.
      if @deleted_sprint_ids.delete parseInt(task.jira_sprint_mountpoint_id)
        return true

      # Fix version is removed from Jira. Ignore.
      if @deleted_fix_version_ids.delete parseInt(task.jira_fix_version_mountpoint_id)
        return true

      # The parent isn't under Jira context, ignore.
      if not (parent_task = @tasks_collection.findOne(query, query_options))?
        return true

      # Task is under a Jira mount tree but not a Jira issue (e.g. mountpoints). Block.
      if task.jira_project_id and not task.jira_issue_id?
        throw @_error "jira-update-failed", "This task is part of the Jira context and cannot be removed."

      # Removing a task/issue that's either under roadmap or under another task/issue will delete the task/issue.
      if parent_task.jira_mountpoint_type is "roadmap" or parent_task.jira_issue_id?
        # In multi-parent scenario, block attempt to remove roadmap/issue parent unless all parents are under the Jira mount tree
        all_parent_task_ids = _.map etc.item.parents2, (parent_obj) -> parent_obj.parent
        all_parent_are_under_jira_tree = etc.item.parents2.length is @tasks_collection.find({_id: {$in: all_parent_task_ids}, jira_project_id: {$ne: null}}).count()
        if not (etc.no_more_parents or all_parent_are_under_jira_tree)
          throw @_error "jira-update-failed", "Remove all other parents of this task first. Deleting the task here will remove the corresponding issue in Jira."

        # XXX In Jira if we:
        # XXX - Remove an Epic with childs > childs will become standalone Story/Task/Bug
        # XXX - Remove a Story/Task/Bug > Subtasks will be deleted as well
        # XXX In JustDo we don't allow a task to be removed if it has child tasks, so this code does not handle such situations.
        @deleted_issue_ids.add task.jira_issue_id

        {err, res} = @pseudoBlockingJiraApiCallInsideFiber "issues.deleteIssue", {issueIdOrKey: task.jira_issue_id}, @getJiraClientForJustdo(task.project_id).v2
        if err?
          throw @_error "jira-update-failed", "Failed to remove task #{task.title}", err

        @tasks_collection.remove task_id
        return true

      if parent_task?.jira_sprint_mountpoint_id?
        # If "task_id:sprint_id" is found in removed_sprint_parent_issue_pairs,
        # it means this action is meant to be omitted (likely using addParent() or reopening a sprint).
        # In this case we don't have to call moveIssuesToBacklog(), or it will remove the sprint of the issue completely.
        if not @removed_sprint_parent_issue_pairs.delete("#{task_id}:#{parent_task.jira_sprint_mountpoint_id}")
          client = @getJiraClientForJustdo(task.project_id).agile
          {err} = @pseudoBlockingJiraApiCallInsideFiber "backlog.moveIssuesToBacklog", {issues: ["#{task.jira_issue_id}"]}, client
          if err?
            throw @_error "jira-update-failed", "Failed to remove #{task.title} from #{parent_task.title}", err

        return true

      if (fix_version_id = parent_task?.jira_fix_version_mountpoint_id)?
        if not @removed_fix_version_parent_issue_pairs.delete "#{task_id}:#{fix_version_id}"
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
        throw @_error "jira-update-failed", "You can't put it here."

      query = _.extend {_id: task_id}, jira_relevant_task_query
      query_options = {fields: _.extend {jira_issue_type: 1, project_id: 1}, jira_relevant_task_fields}
      # Ignore non-Jira tasks, except if the new parent is under Jira context.
      if not (task = @tasks_collection.findOne query, query_options)?
        if new_parent_task?.jira_project_id?
          return
        return true

      # Block attempts to move hardcoded tasks such as mountpoints/sprints/fix-versions
      if (task.jira_mountpoint_type? and task.jira_mountpoint_type isnt "root") or task.jira_sprint_mountpoint_id? or task.jira_fix_version_mountpoint_id?
        throw @_error "jira-update-failed", "You can't move this around."

      # This block specifically handles tasks that are linked to a Jira issue under a mounted tree
      # XXX Move parent-change API-calls from collection hooks to here
      # This block handles the hierachy within Jira issues
      if (jira_issue_id = task.jira_issue_id)?
        # Maintain the Epic-[Task/Story/Bug]-Subtask hierarchy.
        # Refer to comments in @getIssueTypeRank() for issue type rank reference.
        task_issue_type_rank = @getIssueTypeRank task.jira_issue_type, task.jira_project_id

        if new_parent_task?.jira_issue_id?
          new_parent_task_issue_type_rank = @getIssueTypeRank new_parent_task.jira_issue_type, task.jira_project_id

          # Epics cannot be under another issue
          if task_issue_type_rank is 1
            throw @_error "jira-update-failed", "Epics cannot have parent tasks."

          # Task/Story/Bug can only be under Epic
          if task_issue_type_rank is 0 and new_parent_task_issue_type_rank isnt 1
            throw @_error "jira-update-failed", "Story/Task/Bug's parent can only be an Epic."

        # Subtasks has some additional constraints and ops
        if task_issue_type_rank is -1
          # Jira on-perm doesn't support change parent of subtask.
          if @getAuthTypeIfJiraInstanceIsOnPerm()?
            throw @_error "jira-update-failed", "Subtasks are bound to their parent task."

          # Subtasks can only be under Task/Story/Bug
          if new_parent_task_issue_type_rank isnt 0
            throw @_error "jira-update-failed", "Subtask's parent can only be Story/Task/Bug."

          # Update sprint of subtask to be the same as its new parent
          parent_jira_sprint_name = new_parent_task?.jira_sprint
          @tasks_collection.update task._id, {$set: {jira_sprint: parent_jira_sprint_name or null}}

        if (old_parent_task = getParentDocIfPathIsUnderJiraTree path)?
          # Block attempts to move mounted task/issue outside of the tree
          if not new_parent_task?.jira_project_id?
            throw @_error "jira-update-failed", "You can't move this away. Maybe you're looking to add a parent task?"

          # Change sprint for issue
          if old_parent_task.jira_sprint_mountpoint_id? and (new_sprint_id = new_parent_task?.jira_sprint_mountpoint_id)?
            @assignIssueToSprint jira_issue_id, new_sprint_id, task.project_id
            return true

          # Change fix versions for issue
          if (old_fix_version_id = old_parent_task.jira_fix_version_mountpoint_id)? and (new_fix_version_id = new_parent_task?.jira_fix_version_mountpoint_id)?
            @updateIssueFixVersion jira_issue_id, {remove: old_fix_version_id, add: new_fix_version_id}, task.project_id
            return true

      # Move path to individual sprint/fix-version is not supported. Use addParent() instead.
      # Sprint/fix-version swap cases has already been handled.
      if new_parent_task?.jira_sprint_mountpoint_id? or new_parent_task?.jira_fix_version_mountpoint_id?
        throw @_error "jira-update-failed", "You can't move this away. To assign this task to a sprint/fix-version, add the sprint/fix-version as parent of this task."

      return true
