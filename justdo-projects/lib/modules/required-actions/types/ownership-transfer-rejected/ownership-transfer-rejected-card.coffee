Template.required_action_card_ownership_transfer_rejected.onCreated ->
  @show_all = new ReactiveVar false

Template.required_action_card_ownership_transfer_rejected.helpers
  getActionProject: -> APP.collections.Projects.findOne(@project_id, {fields: {title: 1}})

  rejecting_user_obj: -> Meteor.users.findOne(@reject_ownership_message_by)

  showReadMore: -> @reject_ownership_message.length > 80

  showAll: ->
    tpl = Template.instance()

    return tpl.show_all.get()

Template.required_action_card_ownership_transfer_rejected.events
  "click .dismiss": (e, tpl) ->
    APP.projects.modules.owners.dismissOwnershipTransfer(@task_id)

    return

  "click .rm-read-more": (e, tpl) ->
    tpl.show_all.set true

    return

  "click .task-link": ->
    APP.modules.project_page.activateTaskInProject @project_id, @task_id

    return