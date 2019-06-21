curProj = -> APP.modules.project_page.curProj()

Template.task_pane_tasks_locks_section_container.helpers
  isFeatureEnabled: ->
    return curProj().isCustomFeatureEnabled(CustomJustdoTasksLocks.project_custom_feature_id)

Template.task_pane_tasks_locks_section.helpers
  isActiveUserLockingActiveTaskDoc: -> APP.custom_justdo_tasks_locks.isActiveUserLockingActiveTaskDoc()

  getActiveTaskDocLockingUsersDocs: -> APP.custom_justdo_tasks_locks.getActiveTaskDocLockingUsersDocs()
