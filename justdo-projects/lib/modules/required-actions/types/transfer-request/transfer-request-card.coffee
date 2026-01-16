jumpToTask = (project_id, task_id) ->
  # If the target task exsists in the current JustDo, simply point to that task
  if JustdoHelpers.currentPageName() == "project" and Router.current().project_id == project_id
    APP.modules?.project_page?.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab task_id
    return

  # Else we have to move to that JustDo before opening that task
  APP.modules?.project_page?.activateTaskInProject project_id, task_id
  return

Template.required_action_card_transfer_request.onCreated ->
  @state = new ReactiveVar "base"
  @show_shortcut_cue = new ReactiveVar false

  return

Template.required_action_card_transfer_request.helpers
  currentOwnerDoc: -> Meteor.users.findOne(@owner_id, {allow_undefined_fields: true})

  currentOwnerDisplayname: -> JustdoHelpers.displayName @owner_id

  getState: ->
    tpl = Template.instance()

    return tpl.state.get()

  showShortcutCue: ->
    tpl = Template.instance()

    return tpl.show_shortcut_cue.get()

  getActionProjectTitle: -> APP.collections.Projects.findOne(@project_id, {fields: {title: 1}})?.title or TAPi18n.__("untitled_project_title")

  taskURL: ->
    return JustdoHelpers.getTaskUrl(@project_id, @task_id)

Template.required_action_card_transfer_request.events
  "click .pre-reject": (e, tpl) ->
    tpl.state.set("pre-reject")

    return

  "click .cancel-reject": (e, tpl) ->
    tpl.state.set("base")

    return

  "click .reject": (e, tpl) ->
    APP.projects.modules.owners.rejectOwnershipTransfer(@task_id, tpl.$("textarea").val())

    task = APP.collections.Tasks.findOne @task_id

    JustdoSnackbar.show
      text: TAPi18n.__ "transfer_request_card_task_rejected", {task_common_name: JustdoHelpers.taskCommonName({title: @title, seqId: @seqId}, 20)}
      duration: 8000
      showDismissButton: true
      actionText: TAPi18n.__ "view"
      onActionClick: (snackbar) =>
        jumpToTask(@project_id, @task_id)
        snackbar.close()

        return

    return

  "click .accept": ->
    update =
      $set:
        owner_id: Meteor.userId()
        pending_owner_id: null

    @projects_obj.items_collection.update(@task_id, update)

    JustdoSnackbar.show
      text: TAPi18n.__ "transfer_request_card_task_accepted", {task_common_name: JustdoHelpers.taskCommonName({title: @title, seqId: @seqId}, 20)}
      duration: 8000
      showDismissButton: true
      actionText: TAPi18n.__ "view" 
      onActionClick: (snackbar) =>
        jumpToTask(@project_id, @task_id)
        snackbar.close()

        return

    return

  "click .task-link": (e) ->
    e.preventDefault()

    if JD.activeJustdoId()? and JD.activeJustdoId() == @project_id
      APP.modules?.project_page?.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab (@task_id)
    else
      APP.modules?.project_page?.activateTaskInProject @project_id, @task_id

    return

Template.required_action_card_transfer_request_input.onRendered ->
  self = @

  required_action_card_transfer_request_tpl =
    Template.closestInstance("required_action_card_transfer_request")

  show_shortcut_cue = required_action_card_transfer_request_tpl.show_shortcut_cue

  $textarea = @$("textarea")

  $textarea.focus()

  $textarea.keydown (e) ->
    if ((e.altKey or e.ctrlKey) and e.keyCode == 13)
      $textarea.closest(".card-with-avatar").find(".reject").click()
    return

  $textarea.autosize
    callback: ->
      Meteor.defer ->
        textarea_height = $textarea.outerHeight()

        if (textarea_height > 40) and not APP.justdo_pwa.isMobileLayout()
          show_shortcut_cue.set true
        else
          show_shortcut_cue.set false

        return

      return

  return
