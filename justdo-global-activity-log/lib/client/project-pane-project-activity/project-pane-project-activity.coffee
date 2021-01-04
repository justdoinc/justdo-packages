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
  most_recent_updated_at = null
  @recent_updatedat_task_tracker = Tracker.autorun =>
    if (doc = APP.collections.Tasks.findOne({}, {sort: {updatedAt: -1, fields: {updatedAt: 1}}}))?
      most_recent_updated_at = doc.updatedAt

    return

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
      if (project_id = APP.modules.project_page.curProj().id)?
        previous_global_changelog_subscription = @global_changelog_subscription

        @global_changelog_subscription = APP.justdo_global_activity_log.subscribeGlobalChangelog
          projects: [project_id]

        # stop after the new subscription established to use mergebox to avoid even sending
        # docs we already have
        previous_global_changelog_subscription?.stop()

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

    return APP.collections.JDGlobalChangelog.find(query, {sort: {when: -1}}).fetch()

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

Template.global_activity_log_project_pane_project_activity.events
  "click .project-log": ->
    gcm = APP.modules.project_page.getCurrentGcm()
    gcm.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(@.task_id)

    return

  "click .filter-toggle": ->
    toggleStatusFilterState()

    return