getTaskDoc = -> @projects_obj.items_collection.findOne(@task_id)

Template.required_action_card_transfer_request.onCreated ->
  @state = new ReactiveVar "base"
  @show_shortcut_cue = new ReactiveVar false

  return

Template.required_action_card_transfer_request.helpers
  current_owner_doc: -> Meteor.users.findOne(@owner_id)

  task_doc: -> getTaskDoc.call(@)

  task_title: -> @title or ""

  getState: ->
    tpl = Template.instance()

    return tpl.state.get()

  showShortcutCue: ->
    tpl = Template.instance()

    return tpl.show_shortcut_cue.get()

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
      text: "Task #{JustdoHelpers.taskCommonName(task, 20)} <strong>Rejected</strong>"
      duration: 8000
      actionText: "View"
      onActionClick: =>
        APP.modules.project_page.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(task._id)
        JustdoSnackbar.close()

        return

    return

  "click .accept": ->
    update =
      $set:
        owner_id: Meteor.userId()
        pending_owner_id: null

    @projects_obj.items_collection.update(@task_id, update)

    task = APP.collections.Tasks.findOne @task_id

    JustdoSnackbar.show
      text: "Task #{JustdoHelpers.taskCommonName(task, 20)} <strong>Accepted</strong>"
      duration: 8000
      actionText: "View"
      onActionClick: =>
        APP.modules.project_page.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(task._id)
        JustdoSnackbar.close()

        return

    return

  "click .task-link": ->
    APP.projects.modules.required_actions.activateTaskOnMainTab(@_id)

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

        if textarea_height > 40
          show_shortcut_cue.set true
        else
          show_shortcut_cue.set false

        return

      return

  return
