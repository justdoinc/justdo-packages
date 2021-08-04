changeLogSubs = new SubsManager {cacheLimit: 30, expireIn: 2}
current_handle = null
filter_for_status_changes = new ReactiveVar false

Template.task_pane_task_changelog.onCreated ->
  @autorun ->
    if (active_item_id = APP.modules.project_page.activeItemId())?
      current_handle = changeLogSubs.subscribe "taskChangelog", active_item_id

Template.task_pane_task_changelog.onDestroyed ->
  current_handle = null

Template.task_pane_task_changelog.helpers
  changeLogRecords: ->
    query =
      task_id: APP.modules.project_page.activeItemId()

    options =
      sort:
        when: -1

      allow_undefined_fields: true

    logs = []
    logs_time = {}

    APP.collections.TasksChangelog.find(query, options).forEach (log) ->
      log_type_id = "#{log.task_id}-#{log.field}-#{log.by}"
      if (newer_logs_time = logs_time[log_type_id])?
        for newer_time in newer_logs_time
          if moment(newer_time).diff(moment(log.when), "minute") < 2
            return
      
      logs.push log
      
      if not logs_time[log_type_id]?
        logs_time[log_type_id] = []
      
      logs_time[log_type_id].push log.when
      
      return
    
    return logs

  dataLoaded: -> current_handle?.ready()

  filterForStatusChanges: ->
    return filter_for_status_changes.get()

Template.task_pane_task_changelog.events
  "click .filter-toggle" : (e) ->
    filter_for_status_changes.set(not filter_for_status_changes.get())


Template.task_pane_task_changelog_record.helpers
  changingUser: ->
    return APP.helpers.getUserDocById(@by, {user_fields_reactivity: false, missing_users_reactivity: true, get_docs_by_reference: true})

  formatedLabel: ->
    if @change_type == 'moved_to_task' \
        or @change_type == 'users_change' \
        or @field == 'owner_id' \
        or @change_type == 'created'
      return ''

    return JustdoHelpers.ucFirst(@label)

  involvesAnotherTask: ->
    ops_involve_another_task = ["moved_to_task", "add_parent", "remove_parent"]
    return ops_involve_another_task.includes @change_type

  formatedValue: -> APP.tasks_changelog_manager.getActivityMessage(@)

  filtered: ->
    # if the filter is off, nothing is filtered
    if (filter_for_status_changes.get() == false)
      return false
    # filter is on:
    if @field == "status"
      return false
    return true

