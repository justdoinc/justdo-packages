max_printed_task_title = 60

gridControlMux = -> APP.modules.project_page.grid_control_mux?.get()

APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  target_select_pickers = ["#ticket-queue-id", "#ticket-assigned-user-id"]

  project_page_module.setNullaryOperation "ticketEntry",
    human_description: "Quick Add"
    template:
      custom_icon_html: """<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#file"/></svg>"""
    op: ->
      message_template =
        APP.helpers.renderTemplateInNewNode(Template.ticket_entry, {})

      preBootboxDestroyProcedures = ->
        # We destroy the selectors here and not under destroy since
        # when the bootbox is closed while picker is open, it remains
        # open until close animation completed, and it looks bad.
        for selector in target_select_pickers
          $(selector).selectpicker "destroy"

      bootbox.dialog
        title: "Quick Add"
        message: message_template.node
        className: "ticket-entry-dialog bootbox-new-design"
        onEscape: ->
          preBootboxDestroyProcedures()
        buttons:
          cancel:
            label: "Cancel"

            className: "btn-light"

            callback: =>
              preBootboxDestroyProcedures()

          submit:
            label: "Submit"

            callback: =>
              submit_attempted.set true

              selected_owner_id = selected_owner.get()

              destination_type = selected_destination_type_reactive_var.get()

              if destination_type == "ticket-queue"
                if not selected_owner_id?
                  selected_owner_id = getSelectedTicketsQueueDoc().owner_id

              if not formIsValid()
                return false

              grid_control = project_page_module.gridControl(false)
              grid_data = grid_control._grid_data

              # XXX Note that we don't provide path to addChild when destination_type is "ticket-queue". addChild will transform
              # the queue id to a path under root in the path normalization process:
              # "/tickets_queue_id/". This might stop working in future API changes
              # as addChild isn't meant to be used this way.
              task_fields =
                title: title.get()
                priority: priority.get()
                description: $("#ticket-content").froalaEditor("html.get")
                pending_owner_id:
                  if Meteor.userId() != selected_owner_id \
                    then selected_owner_id \
                    else null

              activateItemId = (item_id, options) ->
                item_doc = APP.collections.Tasks.findOne({_id: item_id, project_id: project_page_module.helpers.curProj().id})

                title = "Task <b>##{item_doc.seqId}: #{JustdoHelpers.ellipsis(item_doc.title, 50)}</b> added"
                if (destination_title = options.destination_title)?
                  title += " to <b>#{destination_title}</b>"

                if (pending_owner_id = task_fields.pending_owner_id)?
                  title += " assigned to <b>#{JustdoHelpers.displayName(Meteor.users.findOne(pending_owner_id))}</b>"

                JustdoSnackbar.show
                  text: title
                  duration: 7000
                  actionText: "View"
                  showDismissButton: true
                  onActionClick: =>
                    JustdoSnackbar.close()

                    gridControlMux()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(item_id)

                    return

                return

              grid_control._performLockingOperation (releaseOpsLock, timedout) =>
                destination_title = $("div.ticket-category-select button")?.attr("title")
                if destination_type == "ticket-queue"
                  Meteor.call "newTQTicket",
                    {
                      project_id: project_page_module.helpers.curProj().id,
                      tq: selected_destination_id.get()
                    },
                    task_fields,
                    (err, task_id) ->
                      # XXX see above note, can't rely on new_item_path
                      if err?
                        project_page_module.logger.error "Failed: #{err}"

                        releaseOpsLock()

                        return

                      activateItemId(task_id, {destination_title})

                      releaseOpsLock()

                      return

                if destination_type == "projects"
                  task_fields.project_id = JD.activeJustdoId()
                  grid_data.addChild "/#{selected_destination_id.get()}/", task_fields, (err, task_id) ->
                    if err?
                      project_page_module.logger.error "Failed: #{err}"

                      releaseOpsLock()

                    activateItemId(task_id, {destination_title})

                    releaseOpsLock()

                    return

                return
              preBootboxDestroyProcedures()

              return true

      return
    prereq: ->
      prereq = JustdoHelpers.prepareOpreqArgs()

      if not APP.collections.TicketsQueues.findOne({}, {fields: {_id: 1}})?
        prereq.no_tickets = "No ticket queues are set for this JustDo"

      return prereq

  formIsValid = -> selected_destination_id.get()? and not _.isEmpty(title.get())

  selected_destination_id = new ReactiveVar null
  selected_destination_type_reactive_var = new ReactiveVar null
  title = new ReactiveVar null
  selected_owner = new ReactiveVar null
  description = new ReactiveVar null
  priority = new ReactiveVar null
  submit_attempted = new ReactiveVar null
  initReactiveVars = ->
    selected_destination_id.set null
    selected_destination_type_reactive_var.set null
    title.set ""
    selected_owner.set null
    description.set ""
    priority.set 0
    submit_attempted.set false
    return

  getSelectedTicketsQueueDoc = -> APP.collections.TicketsQueues.findOne selected_destination_id.get()

  tickets_queues_reactive_var = null
  selected_destination_users_reactive_var = null
  task_user_subscription_handler = null

  Template.ticket_entry.onCreated ->
    # Init reactive vars
    initReactiveVars()

    # Subscribe to task augmented fields when changing destination task for displaying task owner options
    @autorun ->
      task_user_subscription_handler = JD.subscribeItemsAugmentedFields selected_destination_id.get(), ["users"]
      return

    tickets_queues_reactive_var = APP.helpers.newComputedReactiveVar "tickets_queues", ->
      return APP.collections.TicketsQueues.find({}, {sort: {title: 1}}).fetch()

    selected_destination_users_reactive_var = APP.helpers.newComputedReactiveVar "selected_destination_users", ->
      destination_type = selected_destination_type_reactive_var.get()

      if not (selected_destination = selected_destination_id.get())?
        return []

      if destination_type == "projects"
        selected_destination_doc = APP.collections.Tasks.findOne selected_destination

      if destination_type == "ticket-queue"
        selected_destination_doc = getSelectedTicketsQueueDoc()

      if not selected_destination_doc?
        return []

      selected_owner.set selected_destination_doc.owner_id
      owner_doc = APP.helpers.getUsersDocsByIds([selected_destination_doc.owner_id])
      tickets_queue_users = APP.collections.TasksAugmentedFields.findOne(selected_destination_doc._id, {fields: {users: 1}})?.users
      other_users_docs = APP.helpers.getUsersDocsByIds(_.without(tickets_queue_users, selected_destination_doc.owner_id))

      return owner_doc.concat(other_users_docs)

    return

  Template.ticket_entry.onRendered ->
    for selector in target_select_pickers
      $(selector)
        .selectpicker
          container: "body"
          size: 6
          width: "100%"
          sanitize: false
        .on "show.bs.select", (e) ->
          setTimeout ->
            $(e.target).focus()
          , 0

    @selectpicker_loaded = true

    tickets_queues_reactive_var.on "computed", ->
      Meteor.defer =>
        destination_type = selected_destination_type_reactive_var.get()

        if destination_type == "ticket-queue"
          if selected_destination_id.get() not in _.map(tickets_queues_reactive_var.get(), (queue) -> queue._id)
            # If selected ticket queue removed as ticket queue
            selected_destination_id.set(null)
            $("#ticket-queue-id").val("")

        $("#ticket-queue-id").selectpicker("refresh")

        return

    selected_destination_users_reactive_var.on "computed", ->
      Meteor.defer =>
        if selected_owner.get() not in _.map(selected_destination_users_reactive_var.get(), (user) -> user._id)
          # If selected user is no longer member of ticket queue
          selected_owner.set(null)
          $("#ticket-assigned-user-id").val("")

        # Select the first option, which is the ticket owner, by default
        $("#ticket-assigned-user-id")[0].selectedIndex = 0
        $("#ticket-assigned-user-id").selectpicker("refresh")
        return

    $("#ticket-content").froalaEditor({
        toolbarButtons: ["bold", "italic", "underline", "strikeThrough", "color", "insertTable", "fontFamily", "fontSize",
          "align", "formatUL", "formatOL", "quote", "insertLink", "clearFormatting", "undo", "redo"]
        pasteImage: false
        imageUpload: false
        height: 250
        heightMin: 250
        heightMax: 250
        quickInsertTags: []
        charCounterCount: false
        key: env.FROALA_ACTIVATION_KEY
      })
      .on "froalaEditor.image.beforePasteUpload", (e, editor, img) ->
        return false
      .on "froalaEditor.image.beforeUpload", (e, editor, images) ->
        return false
      .on "froalaEditor.image.loaded", (e, editor, images, b, c) ->
        return false
      .on "froalaEditor.image.error", (e, editor, error, resp) ->
        console.log error
        return

    priority_slider = Template.justdo_priority_slider.getInstance "ticket-entry-priority-slider"
    priority_slider.onChange (value) ->
      priority.set value

    return

  Template.ticket_entry.onDestroyed ->
    tickets_queues_reactive_var.stop()
    tickets_queues_reactive_var = null

    selected_destination_users_reactive_var.stop()
    selected_destination_users_reactive_var = null

    initReactiveVars()
    return

  Template.ticket_entry.helpers
    isTaskOwner: (index) ->
      if index is 0
        return true
      return false
    tickets_queues: -> tickets_queues_reactive_var.get()
    projects: ->
      tpl = Template.instance()

      projects = APP.justdo_delivery_planner.getKnownProjects(JD.activeJustdoId, {active_only: true}, Meteor.userId())
      Meteor.defer =>
        if tpl.selectpicker_loaded
          $("#ticket-queue-id").selectpicker("refresh")

        return
      return projects
    selected_destination_id: -> selected_destination_id.get()
    selected_destination_type: -> selected_destination_type_reactive_var.get()
    selected_destination_type_has_users: -> selected_destination_type_reactive_var.get() in ["ticket-queue", "projects"]
    selected_destination_users: -> selected_destination_users_reactive_var.get()
    max_printed_task_title: max_printed_task_title
    max_printed_display_name: 40
    isCategoryManager: ->
      current_tickets_queue_doc = APP.collections.TicketsQueues.findOne(selected_destination_id.get())

      if not current_tickets_queue_doc?
        # Can happen while reactive state is in calculation process
        return false

      return @_id == current_tickets_queue_doc.owner_id

    isInvalidTitle: -> submit_attempted.get() and _.isEmpty(title.get())
    isInvalidTicketsQueue: -> submit_attempted.get() and not selected_destination_id.get()?

  Template.ticket_entry.events
    "change #ticket-queue-id": ->
      [destination_type, task_id] = $('#ticket-queue-id').val().split("::")
      selected_destination_type_reactive_var.set(destination_type)
      selected_destination_id.set(task_id)
      return

    "change #ticket-assigned-user-id": ->
      user_id = $('#ticket-assigned-user-id').val()

      if user_id == ""
        user_id = null

      selected_owner.set(user_id)
      return

    "keyup #ticket-title": (e) ->
      title.set($(e.target).val().trim())

  return
