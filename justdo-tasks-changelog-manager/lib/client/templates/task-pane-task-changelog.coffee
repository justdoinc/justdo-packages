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

    newer_log_exists = []
    logs = TasksChangelogManager.getFilteredActivityLogByTime APP.collections.TasksChangelog.find(query, options)

    logs.forEach (log) ->
      # Since the data is sorted by time, we store changed fields inside an array
      # and only show undo button on the newest changelog of the same field.
      if log.field in newer_log_exists and not log.undone
        log.undo_disabled = true
      else
        newer_log_exists.push log.field
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

  formatedValue: ->
    formatted_msg = APP.tasks_changelog_manager.getActivityMessage(@)

    if @change_type in TasksChangelogManager.ops_involve_another_task 
      seqId_regex = new RegExp "#\\d+", "g"
      seqIds_to_replace = formatted_msg.match seqId_regex

      if @old_value? and @old_value isnt "0"
        formatted_msg = formatted_msg.replace seqIds_to_replace.shift(), """<span jd-tt="task-info?id=#{@old_value}&show-title=true">$&</span>"""

      if @new_value isnt "0"
        formatted_msg = formatted_msg.replace seqIds_to_replace.shift(), """<span jd-tt="task-info?id=#{@new_value}&show-title=true">$&</span>"""

    return formatted_msg

  # undo-able, not undoable.
  undoable: -> not @undo_disabled and (@old_value? or @old_value is null) and @change_type not in TasksChangelogManager.not_undoable_ops

  oldValue: -> APP.tasks_changelog_manager.getHumanReadableOldValue @

  filtered: ->
    if (APP.tasks_changelog_manager.changelog_types_filtered_from_ui.has(@change_type))
      return true

    # if the filter is off, nothing is filtered
    if (filter_for_status_changes.get() == false)
      return false
    # filter is on:
    if @field == "status"
      return false
    return true

Template.task_pane_task_changelog_record.events
  "click .undo": (e, tpl) ->
    APP.tasks_changelog_manager.undoActivity @
    return
