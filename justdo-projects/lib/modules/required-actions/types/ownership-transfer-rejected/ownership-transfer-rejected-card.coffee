Template.required_action_card_ownership_transfer_rejected.onCreated ->
  @show_all = new ReactiveVar false

Template.required_action_card_ownership_transfer_rejected.helpers
  getActionProjectTitle: -> APP.collections.Projects.findOne(@project_id, {fields: {title: 1}})?.title or TAPi18n.__("untitled_project_title")

  rejectingUserObj: -> Meteor.users.findOne(@reject_ownership_message_by, {allow_undefined_fields: true})

  rejectingUserName: -> 
    user = Meteor.users.findOne(@reject_ownership_message_by, {allow_undefined_fields: true})
    return JustdoHelpers.displayName user

  showReadMore: -> @reject_ownership_message.length > 80

  showAll: ->
    tpl = Template.instance()

    return tpl.show_all.get()

  taskURL: ->
    return JustdoHelpers.getTaskUrl(@project_id, @task_id)

Template.required_action_card_ownership_transfer_rejected.events
  "click .dismiss": (e, tpl) ->
    APP.projects.modules.owners.dismissOwnershipTransfer(@task_id)

    return

  "click .rm-read-more": (e, tpl) ->
    tpl.show_all.set true

    return

  "click .task-link": (e) ->
    e.preventDefault()

    if JD.activeJustdoId()? and JD.activeJustdoId() == @project_id
      APP.modules?.project_page?.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab @task_id
    else
      APP.modules?.project_page?.activateTaskInProject @project_id, @task_id

    return