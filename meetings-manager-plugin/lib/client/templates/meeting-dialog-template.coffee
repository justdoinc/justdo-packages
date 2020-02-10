Forms.mixin Template.meetings_meeting_dialog

# Functions
saveTasksOrder = (tmpl) ->
  meeting_id = tmpl.data.meeting_id
  list = $("div.meetings_dialog-task")
  tmpl.meetings_tasks_noRender.set true

  if list.length > 0
    for i in [0..list.length-1]
      item = list[i].$blaze_range.view._templateInstance.data.item
      APP.meetings_manager_plugin.meetings_manager.setMeetingTaskOrder meeting_id, item.task_id, i, (e,r) ->
        tmpl.meetings_tasks_noRender.set false


Template.meetings_meeting_dialog.onCreated ->
  @note_out_of_date = new ReactiveVar false
  @minimized = new ReactiveVar false
  @agenda_edit_mode = new ReactiveVar false
  @meetings_tasks_noRender = new ReactiveVar false
  @project_id = Router.current().project_id

  @autorun =>
    data = Template.currentData()

    APP.meetings_manager_plugin.meetings_manager.subscribeToPrivateNotesForMeeting data.meeting_id
    APP.meetings_manager_plugin.meetings_manager.subscribeToNotesForMeeting data.meeting_id

  @autorun =>
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: Template.currentData().meeting_id
    form = Forms.instance()
    form.original meeting || {}

    Tracker.autorun =>
      form.doc form.original()

  @autorun =>
    cur_item = APP.modules.project_page.activeItemObj()

    if cur_item?
      Forms.instance().doc "seqId", cur_item.seqId

  # Get recent locations
  locations = []
  meetings = APP.meetings_manager_plugin.meetings_manager.meetings.find().fetch()
  meetings = _.sortBy(meetings, "updatedAt").reverse()

  $(meetings).each ->
    if this.location? and _.indexOf(locations, this.location) < 0
      locations.push this.location
      if locations.length >= 5
        return false

  Template.currentData().locations = locations

  # Get current project_id
  @autorun =>
    route_name = Router.current().route.getName()
    current_project_id = Router.current().project_id

    if (current_project_id? and current_project_id != @project_id) or !current_project_id?
      $(".meetings_meeting-dialog").remove()

  @html_representation = ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: Template.currentData().meeting_id

    #attended:
    attended_html = ""
    for user_id in meeting.users
      user = Meteor.users.findOne user_id
      attended_html += """<span class="mr-2">#{JustdoHelpers.xssGuard user.profile.first_name} #{JustdoHelpers.xssGuard user.profile.last_name},</span>"""

    attended_html = attended_html.substring(0, attended_html.length - 8) + "</span>"

    #tasks:
    tasks_html = ""
    tasks = _.sortBy meeting.tasks, 'task_order'
    for item in tasks
      tasks_html += """<div class="print-meeting-mode-task my-3 p-3"><h5 class="font-weight-bold"><span class="bg-light border px-2 rounded mr-1">#{item.seqId}</span> #{JustdoHelpers.xssGuard item.title}</h5>"""

      meeting_task = APP.meetings_manager_plugin.meetings_manager.meetings_tasks.findOne
        _id: item.id

      if meeting_task?.added_tasks?.length > 0
        tasks_html += """<div class="mt-3 mb-2 font-weight-bold">Tasks Added:</div><ul>"""
        for task_added in meeting_task.added_tasks
          user_name = ""
          if (task_obj = JD.collections.Tasks.findOne task_added.task_id)?
            user_id = task_obj.owner_id
            if task_obj.pending_owner_id
              user_id = task_obj.pending_owner_id
            user = Meteor.users.findOne user_id
            user_name = """<span class="mr-2">#{JustdoHelpers.xssGuard user.profile.first_name} #{JustdoHelpers.xssGuard user.profile.last_name},</span>"""
          tasks_html += """<li><span class="bg-light border px-2 rounded mr-1">#{task_added.seqId}</span> #{user_name} #{JustdoHelpers.xssGuard task_added.title}</li>"""
        tasks_html += "</ul>"

      if meeting_task?.note?

        key = "12Q97yh66tryb5"
        re =new RegExp(key,'g')
        note = meeting_task.note.replace /\n/g, key
        note = JustdoHelpers.xssGuard note
        note = """<div dir="auto" class="print-meeting-mode-note">""" + note.replace(re, "</div><div dir='auto'>") + "</div>"
        tasks_html += note

      tasks_html += "</div>"

    bottomNote = "None"
    if meeting.note?
      key = "12Q97yh66tryb5"
      re =new RegExp(key,'g')
      bottomNote = meeting.note
      bottomNote = bottomNote.replace /\n/g, key
      bottomNote = JustdoHelpers.xssGuard bottomNote
      bottomNote = "<div dir='auto' class='print-meeting-mode-note'>" + bottomNote.replace(re, "</div><div dir='auto'>") + "</div>"


    ret = """
      <img src="/layout/logos-ext/justdo_logo_with_text_normal.png" alt="justDo" class="thead-logo">
      <h3 class="font-weight-bold mt-4">#{JustdoHelpers.xssGuard meeting.title}</h3>
      <div class="border-bottom pb-3">
        <span class="mr-2">Date: <strong>#{moment(meeting.date).format("YYYY-MM-DD")}</strong>,</span>
        <span class="mr-2">Time: <strong>#{JustdoHelpers.xssGuard(meeting.time)}</strong>,</span>
        <span class="mr-2">Location: <strong>#{JustdoHelpers.xssGuard meeting.location}</strong></span>
      </div>
      <div class="border-bottom py-3">
        <div class="h3 font-weight-bold">Invited</div>
        #{attended_html}
      </div>
      <div class="border-bottom py-3">
        <div class="h3 font-weight-bold">Meeting Notes</div>
        #{tasks_html}
      </div>
      <div class="py-3">
        <div class="h3 font-weight-bold">Other Notes</div>
        #{bottomNote}
      </div>
      """
    return ret

  @print_me = ->
    #preps
    $("body").append """<div class="print-meeting-mode-overlay"></div>"""
    prev_overflow =  $("html").css("overflow")
    $("html").css "overflow", "auto"

    $(".print-meeting-mode-overlay").html @html_representation()

    printAndClean = ->
      window.print()
      $("html").css "overflow", prev_overflow
      $(".print-meeting-mode-overlay").remove()

    img = document.querySelector('img.thead-logo')
    if img.complete
      printAndClean()
    else
      img.addEventListener 'load', printAndClean

    img.addEventListener 'error', printAndClean

  @copy_me = ->
    clipboard.copy
      "text/plain": @plain_text_representation()
      "text/html": @html_representation()

  @plain_text_representation = ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: Template.currentData().meeting_id

    ret = "#{meeting.title} - Meeting Notes\n"
    ret += "#{moment(meeting.date).format("YYYY-MM-DD")} #{meeting.time} #{meeting.location}\n"

    ret += "Invited:\n"

    for user_id in meeting.users
      user = Meteor.users.findOne user_id
      ret += "* #{user.profile.first_name} #{user.profile.last_name}\n"

    ret+= "\n"
    ret += "Agenda Notes:\n\n"
    tasks = _.sortBy meeting.tasks, 'task_order'
    for item in tasks
      ret += "#{item.seqId} #{item.title}\n"

      meeting_task = APP.meetings_manager_plugin.meetings_manager.meetings_tasks.findOne
        _id: item.id

      if meeting_task?.added_tasks?.length > 0
        ret += "Tasks Added:\n"
        for task_added in meeting_task.added_tasks
          ret += "*#{task_added.seqId} #{task_added.title}\n"

      if meeting_task?.note?
        ret += "Notes:\n#{meeting_task.note}\n"
      ret += "\n"

    if meeting.note?
      ret += "Other Notes:\n#{meeting.note}\n"
    return ret.replace /\n/g,"\n"

  @email_me = ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: Template.currentData().meeting_id

    emails=""
    for user_id in meeting.users
      user = Meteor.users.findOne user_id
      emails += "#{user.emails[0].address},"

    window.open("mailto:#{emails}?subject=#{encodeURIComponent(meeting.title)} - Meeting Notes&body=#{encodeURIComponent(@plain_text_representation())}");



Template.meetings_meeting_dialog.onRendered ->
  instance = this
  meeting_note_box = @$ "[name=\"note\"]"
  meeting_note_box.autosize()

  # @$(".modal-content").resizable()

  @$(".meeting-date").datepicker onSelect: (date) ->
    $(".meeting-date-label").text date
    return

  # Make tasks sortable
  meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
    _id: Template.currentData().meeting_id

  @$(".meeting-tasks-list").sortable
    handle: ".sort-task"
    start: (event, ui) ->
      if meeting.status == "draft"
        $(".meeting-tasks").addClass "dragging"

    stop: (event, ui) ->
      if meeting.status == "draft"
        Session.set "updateTaskOrder", true
        $(".meeting-tasks").removeClass "dragging"

  @autorun =>
    updateTaskOrder = Session.get "updateTaskOrder"
    if updateTaskOrder
      saveTasksOrder(instance)
      Session.set "updateTaskOrder", false


Template.meetings_meeting_dialog.helpers

  meeting: -> APP.meetings_manager_plugin.meetings_manager.meetings.findOne
    _id: @meeting_id

  meeting_title: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: @meeting_id
    if meeting.title == "Untitled Meeting"
      return ""
    return meeting.title

  meeting_title_raw: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: @meeting_id
    return meeting.title

  minimizedClass: ->
    if Template.instance().minimized.get() then "minimized" else "maximized"

  mayLock: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
     _id: @meeting_id

    return meeting.organizer_id == Meteor.userId()

  mayLockClass: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: @meeting_id

    if meeting.organizer_id == Meteor.userId() then "may-edit"

  note_out_of_date: ->
    Template.instance().note_out_of_date.get()

  mayEdit: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: @meeting_id

    return meeting.organizer_id == Meteor.userId() or not meeting.locked

  mayEditAgenda: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: @meeting_id

    return (meeting.status != "adjourned") and (meeting.status != "canceled") and
            (meeting.organizer_id == Meteor.userId() or not meeting.locked)

  onSaveMeetingNote: ->
    tmpl = Template.instance()
    id = @meeting_id
    return (changes) =>
      changes =
        note_lock: changes.lock
        note: changes.content

      APP.meetings_manager_plugin.meetings_manager.updateMeetingMetadata id, changes, (err) =>
        if err
          # Invalidate the form and show the user an error.
          tmpl.form.invalidate [{ error: err, name: "note", message: "Update failed: " + err }]

          # Log an error using the logger
          APP.meetings_manager_plugin.logger.error err

  mayNotEditMeetingNote: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: @meeting_id

    return not (
      (meeting.status == "in-progress" or meeting.status == "pending") and
      (meeting.organizer_id == Meteor.userId() or not meeting.locked)
    )

  lookupUser: ->
    Meteor.users.findOne this.user_id

    APP.meetings_manager_plugin.meetings_manager.meetings_private_notes.findOne
      meeting_id: meeting_id
      task_id: @task_id
      user_id: Meteor.userId()

  noRander: ->
    return Template.instance().meetings_tasks_noRender.get()

  tasks: ->

    meeting_id = @meeting_id
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: meeting_id

    tasks = _.sortBy meeting.tasks, 'task_order'

    tasks = _.map tasks, (item) ->
      task =
        item: item
        meeting: meeting
        task: APP.collections.Tasks.findOne
          _id: item.task_id
        meeting_task: APP.meetings_manager_plugin.meetings_manager.meetings_tasks.findOne
          _id: item.id
        private_note: APP.meetings_manager_plugin.meetings_manager.meetings_private_notes.findOne
          meeting_id: meeting_id
          task_id: item.task_id

        task_order: item.task_order

      return task

    return _.filter tasks, _.identity

  datetime: (date) ->
    moment(date).format("MM/DD/YYYY hh:mm a")

  rawdate: (date) ->
    if(date?)
      return moment(date).format("YYYY-MM-DD")
    return ""

  agendaEditClass: ->
    tmpl = Template.instance()
    if tmpl.agenda_edit_mode?.get()
      return "agenda-edit-mode"

  agendaDraftClass: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: @meeting_id

    if meeting.status == "draft"
      return "agenda-draft-mode"

  recentLocations: ->
    return Template.instance().data.locations


  showDiscardButton: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: @meeting_id

    if (meeting.status == "draft" or meeting.status == "pending")
      return true
    return false

  showMeetingNote: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: @meeting_id

    if meeting.status == "draft"
      return false
    return true

  conversationClass: ->
    active_conversation_id = Session.get "active-conversation-id"
    if active_conversation_id? and active_conversation_id == @meeting_id
      return "active"

Template.meetings_meeting_dialog.events

  'click .meeting-print' : (e, tmpl) ->
    tmpl.print_me()

  'click .meeting-email': (e, tmpl) ->
    tmpl.email_me()

  'click .meeting-copy': (e, tmpl) ->
    tmpl.copy_me()
    JustdoSnackbar.show
      text: "Meeting details copied to clipboard."
      duration: 3000
      actionText: "Dismiss"
      onActionClick: =>
        JustdoSnackbar.close()
        return

  "click .meeting-dialog-add-task": (e, tmpl) ->
    $(".meeting-dialog-agenda").animate { scrollTop: $(".meeting-task-add").offset().top }, 500
    $(".meeting-task-add").focus()
    return



  'documentChange .meeting-dialog-info, documentChange .meeting-note': (e, tmpl, doc, changes) ->
    tmpl.form.validate()
    if tmpl.form.isValid()

      if changes.title?
        if (changes.title == "")
          changes.title = "Untitled Meeting"

      if changes.date
        changes.date = moment(changes.date).toDate()

      APP.meetings_manager_plugin.meetings_manager.updateMeetingMetadata doc._id, changes, (err) =>
        if err
          # Invalidate the form and show the user an error.
          tmpl.form.invalidate [{ error: err, name: "", message: "Update failed: " + err }]

          # Log an error using the logger
          APP.meetings_manager_plugin.logger.error err

  'keydown [name="seqId"]': (e, tmpl) ->
    # Click the add-task-btn if the user presses enter in the seqId field
    if e.which == 13
      $(e.currentTarget).trigger 'change'
      tmpl.$(".meeting-add-task .add-task-btn").trigger 'click'
      $(".meeting-task-add").val ""

  # "click .move": (e, tmpl) ->
  #   tmpl.form.validate()
  #
  #   move = if $(e.currentTarget).is(".move-up") then -1 else 1
  #
  #   APP.meetings_manager_plugin.meetings_manager.moveMeetingTask(
  #     this.meeting._id,
  #     this.item.task_id,
  #     move,
  #     (error) ->
  #       if error?
  #         tmpl.form.invalidate [{ error: error, message: error + '', name: "" }]
  #   )
  #
  'click .btn-minimize': (e, tmpl) ->

    tmpl.minimized.set true

  'click .btn-maximize': (e, tmpl) ->
    tmpl.minimized.set false

  #
  # 'click .minimized': (e, tmpl) ->
  #
  #   tmpl.minimized.set false

  'click .meeting-add-task .add-task-btn': (e, tmpl) ->
    # NOTE, Calling validate here clears out any existing errors so that if the
    # last call to validate created a server-inserted error, that error will be
    # hidden.
    tmpl.form.validate("seqId")
    if tmpl.form.isValid("seqId")

      doc = tmpl.form.doc()
      changes = { seqId: doc.seqId }

      if not changes.seqId
        return

      APP.meetings_manager_plugin.meetings_manager.addTaskToMeeting doc._id, changes, (err) =>
        if err
          # Invalidate the form and show the user an error.
          tmpl.form.invalidate [{ error: err, name: "seqId", message: "Adding task failed: " + err }]
          tmpl.form.set "seqId", ""
          Meteor.setTimeout ->
              tmpl?.form?.validate("seqId")
            , 3000

          # Log an error using the logger
          APP.meetings_manager_plugin.logger.error err

        else
          tmpl.form.set "seqId", ""

  'click .meeting-lock': (e, tmpl) ->
    # Clear out any existing errors related to the locked status
    tmpl.form.validate("locked")

    doc = tmpl.form.doc()
    isLocked = doc.locked

    APP.meetings_manager_plugin.meetings_manager.updateMeetingLock doc._id, not isLocked, (err) =>
      if err
        # Invalidate the form and show the user an error.
        tmpl.form.invalidate [{ error: err, name: "locked", message: "Lock/unlock failed: " + err }]

        # Log an error using the logger
        APP.meetings_manager_plugin.logger.error err

  'click .meeting-private': (e, tmpl) ->
    # Clear out any existing errors related to the locked status
    tmpl.form.validate("private")

    doc = tmpl.form.doc()
    isPrivate = doc.private

    APP.meetings_manager_plugin.meetings_manager.updateMeetingPrivacy doc._id, not isPrivate, (err) =>
      if err
        # Invalidate the form and show the user an error.
        tmpl.form.invalidate [{ error: err, name: "private", message: "Make meeting confidential/not-confidential failed: " + err }]

        # Log an error using the logger
        APP.meetings_manager_plugin.logger.error err


  'click .btn-publish-meeting': (e, tmpl) ->
    # Clear out any existing errors related to the locked status
    doc = tmpl.form.doc()
    tmpl.form.validate("status")

    APP.meetings_manager_plugin.meetings_manager.updateMeetingStatus doc._id, "pending", (err) =>
      if err
        # Invalidate the form and show the user an error.
        tmpl.form.invalidate [{ error: err, name: "status", message: "Update status failed: " + err }]

        # Log an error using the logger
        APP.meetings_manager_plugin.logger.error err

  'click .btn-start-meeting': (e, tmpl) ->
    # Clear out any existing errors related to the locked status
    doc = tmpl.form.doc()
    tmpl.form.validate("status")

    APP.meetings_manager_plugin.meetings_manager.updateMeetingStatus doc._id, "in-progress", (err) =>
      if err
        # Invalidate the form and show the user an error.
        tmpl.form.invalidate [{ error: err, name: "status", message: "Update status failed: " + err }]

        # Log an error using the logger
        APP.meetings_manager_plugin.logger.error err


  'click .btn-end-meeting': (e, tmpl) ->
    # Clear out any existing errors related to the locked status
    doc = tmpl.form.doc()
    tmpl.form.validate("status")

    APP.meetings_manager_plugin.meetings_manager.updateMeetingStatus doc._id, "adjourned", (err) =>
      if err
        # Invalidate the form and show the user an error.
        tmpl.form.invalidate [{ error: err, name: "status", message: "Update status failed: " + err }]

        # Log an error using the logger
        APP.meetings_manager_plugin.logger.error err

  "click .btn-cancel-meeting": (e, tmpl) ->
    $(".discard-msg").show()

  "click .btn-discard-ok": (e, tmpl) ->
    # Clear out any existing errors related to the locked status
    doc = tmpl.form.doc()
    tmpl.form.validate("status")

    APP.meetings_manager_plugin.meetings_manager.updateMeetingStatus doc._id, "cancelled", (err) =>
      if err
        # Invalidate the form and show the user an error.
        tmpl.form.invalidate [{ error: err, name: "status", message: "Update status failed: " + err }]

        # Log an error using the logger
        APP.meetings_manager_plugin.logger.error err

  "click .btn-discard-no": (e, tmpl) ->
    $(".discard-msg").hide()

  'click .meeting-dialog-close': (e, tmpl) ->
    APP.meetings_manager_plugin.removeMeetingDialog()

  "keypress [name=\"note\"]": (e, tmpl) ->
    refresh = (target) ->
        $(target).trigger 'change'

    name = e.currentTarget.name
    tmpl._throttled_refresh = tmpl._throttled_refresh || {}
    tmpl._throttled_refresh[name] = tmpl._throttled_refresh[name] || _.throttle refresh, 100

    Meteor.setTimeout =>
      tmpl._throttled_refresh[name](e.currentTarget)
    , 0

  # Show hover msg
  "mouseenter .meeting-lock": () ->
    $(".lock-msg").show()

  "mouseleave .meeting-lock": () ->
    $(".lock-msg").hide()

  # Enter Agenda edit mode
  "click .agenda-edit": (e, tmpl) ->
    tmpl.agenda_edit_mode.set true
    Session.set "tasks_to_remove", []

  # Cancel and Exit Agenda edit mode
  "click .agenda-cancel": (e, tmpl) ->
    tmpl.agenda_edit_mode.set false
    $(".meetings_dialog-task").removeClass "remove"
    $(".btn-agenda-edit").removeClass "recover-task"
    $(".btn-agenda-edit").addClass "remove-task"
    Session.set "updateTaskOrder", true

  # Save and Exit Agenda edit mode
  "click .agenda-save": (e, tmpl) ->
    tmpl.agenda_edit_mode.set false
    $(".meetings_dialog-task").removeClass "remove"
    $(".btn-agenda-edit").removeClass "recover-task"
    $(".btn-agenda-edit").addClass "remove-task"

    meeting_id = tmpl.data.meeting_id
    tasks_to_remove = Session.get "tasks_to_remove"

    for task_id in tasks_to_remove
      APP.meetings_manager_plugin.meetings_manager.removeTaskFromMeeting meeting_id, task_id

    Meteor.setTimeout =>
      Session.set "updateTaskOrder", true
    , 100


  # Select location
  "keyup .meeting-location": (e, tmpl) ->
    $(".wrapper-location").removeClass "open"

    input = $(e.currentTarget)
    if !input.val()
      $(".wrapper-location").addClass "open"

  "click .recent-locations li": (e, tmpl) ->
    location = $(e.currentTarget).html()
    $(".meeting-location").val location
    $(".meeting-location").trigger "change"

  # Meeting conversation
  "click .meeting-conversation": (e, tmpl) ->
    split_view = APP.justdo_split_view
    split_view.size.set(400)
    split_view.position.set("right")

    enabled = split_view.enabled.get()
    url = "https://appear.in/justdo-meetings-" + tmpl.data.meeting_id

    if enabled
      active_conversation_id = Session.get "active-conversation-id"
      current_id = tmpl.data.meeting_id
      if current_id == active_conversation_id
        split_view.enabled.set(false)
        Session.set "active-conversation-id", false
      else
        split_view.url.set(url)
        Session.set "active-conversation-id", current_id
    else
      split_view.enabled.set(true)
      split_view.url.set(url)
      Session.set "active-conversation-id", tmpl.data.meeting_id

    Meteor.setTimeout =>
      $(".justdo-split-view-container").append """<span class="close-split-view" aria-hidden="true"></span>"""
      $(".close-split-view").on "click", ->
        split_view.enabled.set(false)
        Session.set "active-conversation-id", false
    , 300
