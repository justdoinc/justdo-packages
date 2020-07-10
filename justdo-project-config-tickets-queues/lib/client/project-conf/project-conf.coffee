_.extend JustdoProjectConfigTicketsQueues.prototype,
  registerConfigTemplate: ->
    module = APP.modules.project_page

    APP.executeAfterAppClientCode ->
      module.project_config_ui.registerConfigSection "tickets-queues",
        title: "Ticket Queues" # null means no title
        priority: 10

      module.project_config_ui.registerConfigTemplate "tickets-queues",
        section: "tickets-queues"
        template: "justdo_project_config_tickets_queues_project_config"
        priority: 1000

    return

Template.justdo_project_config_tickets_queues_project_config.onCreated ->
  @show_add_button = new ReactiveVar(false)

  @updateAddButtonState = =>
    if $(".new-tq-seqId").val() == ""
      @show_add_button.set(false)
    else
      @show_add_button.set(true)

    return

  @addInputTQ = =>
    seqId = parseInt($(".new-tq-seqId").val(), 10)

    if not (task_doc = APP.collections.Tasks.findOne({project_id: APP.modules.project_page.curProj().id, seqId: seqId}))?
      alert("Unknown task id ##{seqId}")

      return

    if task_doc.is_tickets_queue
      alert("Task ##{seqId} is already a ticket Queue")

      return

    APP.collections.Tasks.update task_doc._id, {$set: {is_tickets_queue: true}}, =>
      $(".new-tq-seqId").val("")

      @updateAddButtonState()

    return

  return

Template.justdo_project_config_tickets_queues_project_config.helpers
  showAddButton: ->
    tpl = Template.instance()

    return tpl.show_add_button.get()

  ticketsQueues: ->
    return APP.collections.TicketsQueues.find({}, {sort: {"seqId": 1}}).fetch()

Template.justdo_project_config_tickets_queues_project_config.events
  "keyup .new-tq-seqId": (e, tpl) ->
    tpl.updateAddButtonState()

    if e.which == 13
      tpl.addInputTQ()

      return

    return

  "click .add": (e, tpl) ->
    tpl.addInputTQ()

    return

Template.ticket_queue_conf.helpers
  isRemovable: -> APP.collections.Tasks.findOne(@_id)?

Template.ticket_queue_conf.events
  "click .removable": ->
    task = APP.collections.Tasks.findOne(@_id)

    APP.collections.Tasks.update @_id, {$set: {is_tickets_queue: false}}, =>
      JustdoSnackbar.show
        text: "Task ##{task.seqId} removed from Ticket Queues"
        actionText: "Undo"
        duration: 7000
        onActionClick: =>
          APP.collections.Tasks.update @_id, {$set: {is_tickets_queue: true}}

          $(".snackbar-container").remove()

          return
    return