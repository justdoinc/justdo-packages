curProj = -> APP.modules.project_page.curProj()

Template.task_pane_tasks_locks_section_container.helpers
  isFeatureEnabled: ->
    return curProj().isCustomFeatureEnabled(CustomJustdoTasksLocks.project_custom_feature_id)

Template.task_pane_tasks_locks_section.helpers
  isActiveUserLockingActiveTaskDoc: -> APP.custom_justdo_tasks_locks.isActiveUserLockingActiveTaskDoc()

  getActiveTaskDocLockingUsersDocs: -> APP.custom_justdo_tasks_locks.getActiveTaskDocLockingUsersDocs()

  taskLockInfo: -> """
    Once you lock a task:
    * No member will be able to remove the task.
    * No member will be able to revoke your access to the task.
    * The fields: Title and Due Date, will be editable only by you, unless there are more locking members, in which case - no one will be able to edit these fields.
  """

Template.task_pane_tasks_locks_section.events
  "click .tasks-locks-toggle-lock-state": ->
    APP.custom_justdo_tasks_locks.toggleActiveTaskLockState()

    return