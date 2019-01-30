getTaskDoc = -> @projects_obj.items_collection.findOne(@task_id)

Template.required_action_card_ownership_transfer_rejected.onCreated ->
  @show_all = new ReactiveVar false

Template.required_action_card_ownership_transfer_rejected.helpers
  task_doc: -> getTaskDoc.call(@)

  task_title: -> @title or ""

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
    APP.projects.modules.required_actions.activateTaskOnMainTab(@_id)