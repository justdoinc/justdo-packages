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

            className: "btn-default"

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

              # XXX Note that we don't provide path to addChild. addChild will transform
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
                        project_page_module.logger.error "add direct task failed: #{err}"

                        releaseOpsLock()

                        return

                      activateItemId(task_id, {destination_title})

                      releaseOpsLock()

                      return

                if destination_type == "direct-task"
                  direct_task_parent_id = selected_destination_id.get()

                  direct_task_parent_id_user = direct_task_parent_id.substr(7)

                  Meteor.call "newDirectTask",
                              {
                                project_id: project_page_module.helpers.curProj().id,
                                user_id: direct_task_parent_id_user
                              },
                              task_fields,
                              (err, task_id) ->
                                # XXX see above note, can't rely on new_item_path
                                if err?
                                  project_page_module.logger.error "add direct task failed: #{err}"

                                  releaseOpsLock()

                                  return

                                activateItemId(task_id, {destination_title})

                                releaseOpsLock()

                                return

                  releaseOpsLock()

              preBootboxDestroyProcedures()

              return true

    prereq: ->
      return {}

  formIsValid = -> selected_destination_id.get()? and not _.isEmpty(title.get())

  selected_destination_id = new ReactiveVar null
  title = new ReactiveVar null
  selected_owner = new ReactiveVar null
  description = new ReactiveVar null
  priority = new ReactiveVar null
  submit_attempted = new ReactiveVar null
  initReactiveVars = ->
    selected_destination_id.set null
    title.set ""
    selected_owner.set null
    description.set ""
    priority.set 0
    submit_attempted.set false

  getSelectedTicketsQueueDoc = -> APP.collections.TicketsQueues.findOne selected_destination_id.get()

  tickets_queues_reactive_var = null
  direct_task_reactive_var = null
  selected_destination_users_reactive_var = null
  selected_destination_type_reactive_var = null
  Template.ticket_entry.onCreated ->
    # Init reactive vars
    initReactiveVars()

    tickets_queues_reactive_var = APP.helpers.newComputedReactiveVar "tickets_queues", ->
      return APP.collections.TicketsQueues.find({}, {sort: {title: 1}}).fetch()

    direct_task_reactive_var = APP.helpers.newComputedReactiveVar "direct_tasks_parents", ->
      project_members_ids = project_page_module.helpers.curProj().getMembersIds()

      cur_user_id = Meteor.userId()

      current_user_doc = APP.helpers.getUsersDocsByIds([cur_user_id])
      other_users_docs = JustdoHelpers.sortUsersDocsArrayByDisplayName(APP.helpers.getUsersDocsByIds(_.without(project_members_ids, cur_user_id)))

      project_members_docs = current_user_doc.concat(other_users_docs)

      direct_tasks = _.map project_members_docs, (memeber_doc) ->
        direct_task = {
          direct_task_id: "direct:#{memeber_doc._id}"
          title: if memeber_doc._id == cur_user_id then "My Direct Tasks" else JustdoHelpers.displayName(memeber_doc)
          memeber_doc: memeber_doc
        }

        direct_task.data_content = JustdoHelpers.xssGuard("""#{JustdoAvatar.getAvatarHtml(direct_task.memeber_doc)}<span class="option-img-text">#{JustdoHelpers.ellipsis(direct_task.title, max_printed_task_title)}</span>""", {allow_html_parsing: true, enclosing_char: ""})

        return direct_task

      return direct_tasks

    selected_destination_type_reactive_var = APP.helpers.newComputedReactiveVar "selected_destination_type", ->
      destination_id = selected_destination_id.get()

      if not destination_id?
        return "none"
      if destination_id.substr(0, 7) == "direct:"
        return "direct-task"

      return "ticket-queue"

    selected_destination_users_reactive_var = APP.helpers.newComputedReactiveVar "selected_destination_users", ->
      destination_type = selected_destination_type_reactive_var.get()

      if destination_type == "direct-task"
        destination_id = selected_destination_id.get()

        if not destination_id?
          return [] # can happen, when selected_destination_type_reactive_var is pending update

        destination_user_id = destination_id.substr(7)
        return [Meteor.users.findOne(destination_user_id)]
      else # for readability
        if not selected_destination_id.get()?
          return []

        selected_tickets_queue_doc = getSelectedTicketsQueueDoc()

        if not selected_tickets_queue_doc?
          return []

        owner_doc = APP.helpers.getUsersDocsByIds([selected_tickets_queue_doc.owner_id])
        other_users_docs = APP.helpers.getUsersDocsByIds(_.without(selected_tickets_queue_doc.users, selected_tickets_queue_doc.owner_id))

        return owner_doc.concat(other_users_docs)

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

    tickets_queues_reactive_var.on "computed", ->
      Meteor.defer =>
        destination_type = selected_destination_type_reactive_var.get()

        if destination_type == "ticket-queue"
          if selected_destination_id.get() not in _.map(tickets_queues_reactive_var.get(), (queue) -> queue._id)
            # If selected ticket queue removed as ticket queue
            selected_destination_id.set(null)
            $("#ticket-queue-id").val("")

        $("#ticket-queue-id").selectpicker("refresh")

    direct_task_reactive_var.on "computed", ->
      Meteor.defer =>
        destination_type = selected_destination_type_reactive_var.get()

        if destination_type == "direct-task"
          if selected_destination_id.get() not in _.map(direct_task_reactive_var.get(), (direct_task_parent) -> direct_task_parent.direct_task_id)
            # If selected ticket queue removed as ticket queue
            selected_destination_id.set(null)
            $("#ticket-queue-id").val("")

        $("#ticket-queue-id").selectpicker("refresh")

    selected_destination_users_reactive_var.on "computed", ->
      Meteor.defer =>
        if selected_owner.get() not in _.map(selected_destination_users_reactive_var.get(), (user) -> user._id)
          # If selected user is no longer member of ticket queue
          selected_owner.set(null)
          $("#ticket-assigned-user-id").val("")

        $("#ticket-assigned-user-id").selectpicker("refresh")

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
      });

    $(".jd-priority-slider-ticket").slider
      range: 'min'
      value: 0
      min: 0
      max: 100
      create: ->
        $(".jd-priority-slider-handle")
      slide: (event, ui) ->
        $(".ui-slider-range").attr("style", "background: " + JustdoColorGradient.getColorRgbString(ui.value or 0) + " !important")
        $(".jd-priority-value").text ui.value
      start: (event, ui) ->
        $(".jd-priority-value").fadeIn()
      stop: (event, ui) ->
        $(".jd-priority-value").fadeOut()
        priority.set ui.value

  Template.ticket_entry.onDestroyed ->
    tickets_queues_reactive_var.stop()
    tickets_queues_reactive_var = null

    direct_task_reactive_var.stop()
    direct_task_reactive_var = null

    selected_destination_users_reactive_var.stop()
    selected_destination_users_reactive_var = null

    selected_destination_type_reactive_var.stop()
    selected_destination_type_reactive_var = null

    initReactiveVars()

  Template.ticket_entry.helpers
    direct_tasks: -> direct_task_reactive_var.get()
    tickets_queues: -> tickets_queues_reactive_var.get()
    selected_destination_id: -> selected_destination_id.get()
    selected_destination_type: -> selected_destination_type_reactive_var.get()
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
      selected_destination_id.set($('#ticket-queue-id').val())

      # init owner selector
      selected_owner.set(null)
      $('#ticket-assigned-user-id').val("")

    "change #ticket-assigned-user-id": ->
      user_id = $('#ticket-assigned-user-id').val()

      if user_id == ""
        user_id = null

      selected_owner.set(user_id)

    "keyup #ticket-title": (e) ->
      title.set($(e.target).val().trim())

    "click .tick-0": (e, tmpl) ->
        priority.set 0
        $(".jd-priority-slider-ticket").slider "value", 0
        $(".jd-priority-value").text("0").fadeIn().fadeOut()

    "click .tick-25": (e, tmpl) ->
        priority.set 25
        $(".jd-priority-slider-ticket").slider "value", 25
        $(".jd-priority-value").text("25").fadeIn().fadeOut()

    "click .tick-50": (e, tmpl) ->
        priority.set 50
        $(".jd-priority-slider-ticket").slider "value", 50
        $(".jd-priority-value").text("50").fadeIn().fadeOut()

    "click .tick-75": (e, tmpl) ->
        priority.set 75
        $(".jd-priority-slider-ticket").slider "value", 75
        $(".jd-priority-value").text("75").fadeIn().fadeOut()

    "click .tick-100": (e, tmpl) ->
        priority.set 100
        $(".jd-priority-slider-ticket").slider "value", 100
        $(".jd-priority-value").text("100").fadeIn().fadeOut()
