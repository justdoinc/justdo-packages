Template.global_activity_log_project_pane_project_activity_container.onCreated ->
  @project_template_refresher = new ReactiveVar(0)

  last_project_id = null
  @autorun =>
    if (cur_project_id = APP.modules.project_page.curProj().id)?
      if cur_project_id != last_project_id
        @project_template_refresher.set((@project_template_refresher.get() + 1) % 2)

    last_project_id = cur_project_id

    return

  return

Template.global_activity_log_project_pane_project_activity_container.helpers
  project_template_refresher: ->
    tpl = Template.instance()

    return tpl.project_template_refresher.get()

status_filter_amplify_key = "project-pane-project-activity-filter-status"
default_status_filter_state = false

status_dep = new Tracker.Dependency()
getStatusFilterState = ->
  status_dep.depend()

  return if (state = amplify.store(status_filter_amplify_key))? then state else default_status_filter_state
toggleStatusFilterState = ->
  status_dep.changed()
  amplify.store(status_filter_amplify_key, not getStatusFilterState())

  return

Template.global_activity_log_project_pane_project_activity.onCreated ->
  @counter = 0
  @loading_new_logs = new ReactiveVar true # To facilitate "Loading more messages" on initial load
  most_recent_updated_at = null
  @recent_updatedat_task_tracker = Tracker.autorun =>
    if (doc = APP.collections.Tasks.findOne({}, {sort: {updatedAt: -1, fields: {updatedAt: 1}}}))?
      most_recent_updated_at = doc.updatedAt

    return

  tpl = @
  @logs_count = 0
  @loading_more_item = false
  @changelog_tasks_limit = JustdoGlobalActivityLog.default_global_changelog_tasks_limit
  @changelog_changelogs_limit = JustdoGlobalActivityLog.default_global_changelog_changelogs_limit
  @refreshChangelogSubscription = ->
    if (project_id = APP.modules.project_page.curProj().id)? and not tpl.loading_more_item
      # Prevent double calling of this function
      tpl.loading_more_item = true

      previous_global_changelog_subscription = tpl.global_changelog_subscription
      previous_subscription_tracker = tpl.current_subscription_tracker

      tpl.global_changelog_subscription = APP.justdo_global_activity_log.subscribeGlobalChangelog
        projects: [project_id]
        tasks_limit: tpl.changelog_tasks_limit
        changelogs_limit: tpl.changelog_changelogs_limit

      tpl.current_subscription_tracker = Tracker.autorun ->
        if tpl.global_changelog_subscription.ready()
          # Allow next call of refreshChangelogSubscription
          tpl.loading_more_item = false
          tpl.loading_new_logs.set false

      # stop after the new subscription established to use mergebox to avoid even sending
      # docs we already have
      previous_global_changelog_subscription?.stop()
      previous_subscription_tracker?.stop()

  min_time_between_updates = 10 * 1000 # 10 seconds
  last_update = null
  next_time_update_allowed = new Date()
  @refreshInterval = setInterval =>
    if not most_recent_updated_at?
      # Tasks didn't finish load, probably.
      return

    if (new Date()) < next_time_update_allowed
      return

    if not last_update? or last_update < most_recent_updated_at
      @refreshChangelogSubscription()
      last_update = new Date()
      next_time_update_allowed = JustdoHelpers.getDateMsOffset(min_time_between_updates)

    return
  , 1000


  return

Template.global_activity_log_project_pane_project_activity.onDestroyed ->
  clearInterval @refreshInterval

  @global_changelog_subscription?.stop()

  @recent_updatedat_task_tracker?.stop()

  return

Template.global_activity_log_project_pane_project_activity.helpers
  activities: ->
    query = {}

    if not getStatusFilterState()
      query.field = "status"

    logs_cursor = APP.collections.JDGlobalChangelog.find(query, {sort: {when: -1}})

    return TasksChangelogManager.getFilteredActivityLogByTime logs_cursor

  getActivityMessage: ->
    return JustdoHelpers.ellipsis(APP.tasks_changelog_manager.getActivityMessage(@), 150)

  getTaskDetails: ->
    task_details = ""
    if (task_doc = APP.collections.Tasks.findOne(@.task_id, {fields: {seqId: 1, title: 1}}))?
      task_details += "##{task_doc.seqId}"

      if (title = task_doc.title)?
        task_details += ": #{JustdoHelpers.ellipsis(title, 70)}"

      task_details += " - "

    return task_details

  negativeDateOrNow: -> JustdoHelpers.negativeDateOrNow(@when)

  isActiveStatusFilter: -> getStatusFilterState()

  loadingNewLogs: -> Template.instance().loading_new_logs.get()

Template.global_activity_log_project_pane_project_activity.events
  "click .project-log": ->
    gcm = APP.modules.project_page.getCurrentGcm()
    gcm.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(@.task_id)

    return

  "click .filter-toggle": ->
    toggleStatusFilterState()

  "scroll .tab-project-activity": (e, tpl)->
    more_item_container_position = $(".tab-project-activity .more-items-container").position().top - $(".tab-project-activity").height()
    updated_logs_count = APP.collections.JDGlobalChangelog.find().count()

    # New subscription is created when
    # 1. Project pane is scrolled to the bottom
    # 2. Previous subscription has finished loading
    # (as .scroll is sensitive and can trigger the following code thousands of times)
    # 3. JDGlobalChangelog collection is updated after previous subscription has finished loading
    # (as we don't want to keep increasing changelog_tasks_limit and changelog_changelogs_limit when there's no new logs)
    if (more_item_container_position < 10) and (not tpl.loading_more_item) and (updated_logs_count > tpl.logs_count)
      tpl.loading_new_logs.set true
      tpl.logs_count = updated_logs_count
      tpl.changelog_tasks_limit += JustdoGlobalActivityLog.default_global_changelog_tasks_limit
      tpl.changelog_changelogs_limit += JustdoGlobalActivityLog.default_global_changelog_changelogs_limit
      tpl.refreshChangelogSubscription()

    return
