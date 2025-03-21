Template.task_pane_justdo_jira_integration_task_pane_section_section.onCreated ->
  @show_unmount_warning_message = new ReactiveVar false

  @available_jira_projects_rv = new ReactiveVar []
  @autorun =>
    # Just to get the reactivity upon choosing a new task or performing new Jira login, in case the previous load failed.
    JD.activeItemId()
    APP.collections.Jira.findOne()
    APP.justdo_jira_integration.getAvailableJiraProjects JD.activeJustdoId(), (err, available_projects) => @available_jira_projects_rv.set available_projects
    return

Template.task_pane_justdo_jira_integration_task_pane_section_section.helpers
  issueUrl: ->
    base_url = APP.collections.Jira.findOne({}, {fields: {server_info: 1}})?.server_info?.url
    issue_key = APP.collections.Tasks.findOne(JD.activeItemId(), {fields: {jira_issue_key: 1}})?.jira_issue_key
    if base_url? and issue_key?
      return new URL "/browse/#{issue_key}", base_url
    return

  mountedJiraProject: ->
    active_task = JD.activeItem({jira_project_id: 1, jira_mountpoint_type: 1})
    if active_task.jira_mountpoint_type is "root"
      jira_project_id = active_task.jira_project_id
      query =
        "jira_projects.#{jira_project_id}":
          $ne: null
      query_options =
        "jira_projects.#{jira_project_id}": 1
      jira_project_key = APP.collections.Jira.findOne(query, query_options)?.jira_projects?[jira_project_id]?.key
      return {jira_project_key, jira_project_id}
    return

  taskIsMountable: ->
    if not (active_task = JD.activeItem({jira_project_id: 1, jira_issue_key: 1, jira_mountpoint_type: 1, jira_sprint_mountpoint_id: 1, jira_fix_version_mountpoint_id: 1}))?
      return false
    delete active_task._id
    return _.every active_task, (field_val) -> _.isNull field_val

  availableProjects: -> Template.instance().available_jira_projects_rv.get()

  showUnmountWarningMessage: -> Template.instance().show_unmount_warning_message.get()

Template.task_pane_justdo_jira_integration_task_pane_section_section.events
  "click .jira-project": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    jira_project_key = $(e.currentTarget).closest(".jira-project").data "project-key"
    jira_project_id = $(e.currentTarget).closest(".jira-project").data "project-id"
    $(e.target.closest(".jira-projects")).html "Mounting project #{jira_project_key}..."
    APP.justdo_jira_integration.mountTaskWithJiraProject JD.activeItemId(), jira_project_id, ->
      jira_doc_id = APP.justdo_jira_integration.getJiraDocIdFromJustdoId JD.activeJustdoId()
      APP.justdo_jira_integration._setupIssueTypeCustomField jira_doc_id
      return

    return

  "click .unmount-jira-project": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()
    tpl.show_unmount_warning_message.set true
    return

  "click .confirm-unmount-jira-project": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    jira_project_id = $(e.currentTarget).closest(".confirm-unmount-jira-project").data "project-id"

    APP.justdo_jira_integration.unmountTaskWithJiraProject JD.activeJustdoId(), jira_project_id
    return

  "click .cancel-unmount-jira-project": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()
    tpl.show_unmount_warning_message.set false
    return
