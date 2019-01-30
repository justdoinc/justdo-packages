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

    return APP.collections.TasksChangelog.find query, options

  dataLoaded: -> current_handle?.ready()

  filterForStatusChanges: ->
    return filter_for_status_changes.get()

Template.task_pane_task_changelog.events
  "click .filter-toggle" : (e) ->
    filter_for_status_changes.set(not filter_for_status_changes.get())


Template.task_pane_task_changelog_record.helpers
  changingUser: -> APP.helpers.getUsersDocsByIds @by

  formatDate: -> moment(new Date(@when)).format('LLL')

  formatedLabel: ->
    if @change_type == 'moved_to_task' \
        or @change_type == 'users_change' \
        or @field == 'owner_id' \
        or @change_type == 'created'
      return ''

    return JustdoHelpers.ucFirst(@label)

  formatedValue: -> APP.tasks_changelog_manager.getActivityMessage(@)

  filtered: ->
    # if the filter is off, nothing is filtered
    if (filter_for_status_changes.get() == false)
      return false
    # filter is on:
    if @field == "status"
      return false
    return true

