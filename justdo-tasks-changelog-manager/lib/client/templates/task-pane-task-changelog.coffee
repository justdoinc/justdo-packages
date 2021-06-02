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
    fields_changed_by_others = []

    APP.collections.TasksChangelog.find(query, options).forEach (log) ->
      log_type_id = "#{log.task_id}-#{log.field}-#{log.by}"
      # If a field is changed by the same user within 2 mins, don't display that log.
      if (newer_logs_time = logs_time[log_type_id])?
        for newer_time in newer_logs_time
          if moment(newer_time).diff(moment(log.when), "minute") < 2
            return

      if not logs_time[log_type_id]?
        logs_time[log_type_id] = []

      logs_time[log_type_id].push log.when

      # Since the data is sorted by time, we store changed fields inside an array
      # and disable undo function for logs where the field was changed by someone else.
      if fields_changed_by_others.includes log.field
        log.undo_disabled = true
      else
        fields_changed_by_others.push log.field

      logs.push log

      return

    return logs

  dataLoaded: -> current_handle?.ready()

  filterForStatusChanges: -> filter_for_status_changes.get()

Template.task_pane_task_changelog.events
  "click .filter-toggle" : (e) ->
    filter_for_status_changes.set(not filter_for_status_changes.get())

Template.task_pane_task_changelog_record.helpers
  changingUser: -> APP.helpers.getUserDocById(@by, {user_fields_reactivity: false, missing_users_reactivity: true, get_docs_by_reference: true})

  formatedLabel: ->
    if @change_type == "moved_to_task" \
        or @change_type == "users_change" \
        or @field == "owner_id" \
        or @change_type == "created"
      return ""

    return JustdoHelpers.ucFirst @label

  formatedValue: -> APP.tasks_changelog_manager.getActivityMessage @

  involvesAnotherTask: ->
    ops_involve_another_task = ["moved_to_task", "add_parent", "remove_parent"]
    return ops_involve_another_task.includes @change_type

  formatedValue: -> APP.tasks_changelog_manager.getActivityMessage(@)
  # undo-able, not undoable.
  undoable: -> not @undo_disabled and (@old_value? or @old_value is null) and (@by is Meteor.userId())

  oldValue: ->APP.tasks_changelog_manager.getOldValueMessage @

  filtered: ->
    # if the filter is off, nothing is filtered
    if (filter_for_status_changes.get() == false)
      return false
    # filter is on:
    if @field == "status"
      return false
    return true

Template.task_pane_task_changelog_record.events
  "click .undo": (e, tpl) ->
    APP.tasks_changelog_manager.undoChange @
