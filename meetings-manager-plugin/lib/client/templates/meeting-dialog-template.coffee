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

showSnackbar = (message) ->
  JustdoSnackbar.show
    text: message
    duration: 4000

setMeetingTime = (tpl, date) ->
  tpl.$(".meeting-time").val(date).change()
  return

setMeetingHours = (tmpl, hours) ->
  meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
    _id: tmpl.data.meeting_id

  if meeting.time?
    time = new Date meeting.time
  else
    time = new Date()
    time.setHours(0, 0, 0, 0)

  $(".meeting-time").val(new Date(time.setHours(time.getHours() + hours))).change()
  return

setMeetingMinutes = (tmpl, minutes) ->
  meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
    _id: tmpl.data.meeting_id

  if meeting.time?
    time = new Date meeting.time
  else
    time = new Date()
    time.setHours(0, 0, 0, 0)

  $(".meeting-time").val(new Date(time.setMinutes(time.getMinutes() + minutes))).change()
  return

addTaskToAgenda = (tmpl) ->

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
        showSnackbar(err.reason)

      else
        tmpl.form.set "seqId", ""

  $(".meeting-task-add").val ""

  return

Template.meetings_meeting_dialog.onCreated ->
  @autorun =>
    data = Template.currentData()
    @meeting_sub = APP.meetings_manager_plugin.meetings_manager.subscribeToMeeting data.meeting_id

    return
    
  @note_out_of_date = new ReactiveVar false
  @minimized = new ReactiveVar false
  @meetings_tasks_noRender = new ReactiveVar false
  @project_id = Router.current().project_id
  @is_editing_location = new ReactiveVar false
  @logo_data_url = null

  toDataURL = (url, callback) ->
    xhr = new XMLHttpRequest();
    xhr.onload = ->
      reader = new FileReader();
      reader.onloadend = ->
        callback(reader.result);
      reader.readAsDataURL(xhr.response);
    xhr.open('GET', url);
    xhr.responseType = 'blob';
    xhr.send();

  toDataURL "/layout/logos-ext/justdo_logo_with_text_normal.png", (data_url) =>
    @logo_data_url = data_url

  

  @autorun =>
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: Template.currentData().meeting_id
    form = Forms.instance()
    form.original meeting || {}

    Tracker.autorun =>
      form.doc form.original()

  # Get current project_id
  @autorun =>
    route_name = Router.current().route.getName()
    current_project_id = Router.current().project_id

    if (current_project_id? and current_project_id != @project_id) or !current_project_id?
      $(".meetings_meeting-dialog").remove()

  @autorun =>
    cur_item = APP.modules.project_page.activeItemObj()
    
    if cur_item? and @meeting_sub?.ready()
      Forms.instance().doc "seqId", cur_item.seqId

      Meteor.defer =>
        match_meeting = APP.meetings_manager_plugin.meetings_manager.meetings_tasks.findOne
          _id: @data.meeting_id
          $or: [
            {task_id: cur_item._id},
            {added_tasks: $elemMatch: {task_id: cur_item._id}}
          ]
        if not match_meeting?
          @$(".meeting-task-add").val(cur_item.seqId)

  @html_representation = ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: Template.currentData().meeting_id

    #attended:
    attended_html = ""
    for user_id in meeting.users
      user = Meteor.users.findOne user_id
      attended_html += """<span class="mr-2">#{JustdoHelpers.xssGuard user.profile.first_name} #{JustdoHelpers.xssGuard user.profile.last_name},</span>"""
    if not _.isEmpty(meeting.other_attendees)
      attended_html += """<span class="mr-2">#{JustdoHelpers.xssGuard meeting.other_attendees}</span>"""

    #tasks:
    tasks_html = ""
    tasks = _.sortBy meeting.tasks, 'task_order'
    for item in tasks
      tasks_html += """<div class="print-meeting-mode-task my-3 p-3"><div class="font-weight-bold"><a href="#{JustdoHelpers.getTaskUrl(@project_id, item.task_id)}">##{item.seqId}: #{JustdoHelpers.xssGuard item.title}</a></div>"""

      meeting_task = APP.meetings_manager_plugin.meetings_manager.meetings_tasks.findOne
        _id: item.id

      if meeting_task?.added_tasks?.length > 0
        tasks_html += """<div class="mt-3 mb-2 font-weight-bold">Child Tasks Added:</div><ul>"""
        for task_added in meeting_task.added_tasks
          user_name = ""
          if (task_obj = JD.collections.Tasks.findOne task_added.task_id)?
            user_id = task_obj.owner_id
            if task_obj.pending_owner_id
              user_id = task_obj.pending_owner_id
            user = Meteor.users.findOne user_id
            user_name = """<span class="mr-2">#{JustdoHelpers.xssGuard user.profile.first_name} #{JustdoHelpers.xssGuard user.profile.last_name},</span>"""
          tasks_html += """<li>#{user_name} #{JustdoHelpers.xssGuard task_added.title}, <span class="bg-light border px-2 rounded mr-1"><a href="#{JustdoHelpers.getTaskUrl(@project_id, task_added.task_id)}">##{task_added.seqId}</a></span>"""
          if task_obj.due_date?
            tasks_html += "<br>Due date: #{moment(task_obj.due_date).format(JustdoHelpers.getUserPreferredDateFormat())}"
          if task_added.note?
            key = "12Q97yh66tryb5"
            re = new RegExp(key,'g')
            note = "Notes: " + task_added.note.replace /<br>/g, key
            note = JustdoHelpers.xssGuard note, {allow_html_parsing: true, enclosing_char: ""}
            note = "<div dir='auto' class='print-meeting-mode-note'>" + note.replace(re, "</div><div dir='auto'>") + "</div>"
            tasks_html += "<i>" + note + "</i>"
          tasks_html += "</li>"
        tasks_html += "</ul>"

      if meeting_task?.note?
        key = "12Q97yh66tryb5"
        re = new RegExp(key,'g')
        note = meeting_task.note.replace /<br>/g, key
        note = JustdoHelpers.xssGuard note, {allow_html_parsing: true, enclosing_char: ""}
        note = """<div dir="auto" class="print-meeting-mode-note">""" + note.replace(re, "</div><div dir='auto'>") + "</div>"
        tasks_html += "<i>" + note + "</i>"

      tasks_html += "</div>"

    bottomNote = "None"
    if meeting.note?
      key = "12Q97yh66tryb5"
      re = new RegExp(key,'g')
      bottomNote = meeting.note
      bottomNote = bottomNote.replace /<br>/g, key
      bottomNote = JustdoHelpers.xssGuard bottomNote, {allow_html_parsing: true, enclosing_char: ""}
      bottomNote = "<div dir='auto' class='print-meeting-mode-note'>" + bottomNote.replace(re, "</div><div dir='auto'>") + "</div>"

    meeting_date = "Date not set"
    if meeting.date?
      meeting_date = moment(meeting.date).format(JustdoHelpers.getUserPreferredDateFormat())

    ret = """
      <img src="#{@logo_data_url}" class="thead-logo" alt="JustDo" width="100px"/>
      <h3 class="font-weight-bold mt-4">#{JustdoHelpers.xssGuard meeting.title}</h3>
      <div>
       <span>Date: <strong> #{meeting_date}</strong></span>
    """

    if meeting.time?
      meeting_time = ""
      use_am_pm = Meteor.user().profile.use_am_pm
      if use_am_pm
        meeting_time = moment(meeting.time).format("h:mm A")
      else
        meeting_time = moment(meeting.time).format("HH:mm")

      ret += """<span>, &nbsp</span><span class="mr-2">Time: <strong>#{JustdoHelpers.xssGuard(meeting_time)}</strong></span></div>"""

    if meeting.location?
      ret += """<div class="mr-2">Location: <strong>#{JustdoHelpers.xssGuard meeting.location}</strong></div>"""

    ret += """
      <div>
        <div>Attendees: <strong>#{attended_html}</strong></div>
      </div>
      <hr>
      <div class="py-1">
        <div class="h3 font-weight-bold"><strong>Agenda:</strong></div>
        #{tasks_html}
      </div>
      <hr>
      """
    
    if meeting.note?
      ret += """
        <div class="py-1">
          <div class="h3 font-weight-bold"><strong>General Meeting Notes</strong></div>
          <i>#{bottomNote}</i>
        </div>
      """
      
    return ret

  @refresh = =>
    new_meeting_sub = APP.meetings_manager_plugin.meetings_manager.subscribeToMeeting Template.currentData().meeting_id, =>
      if @meeting_sub?
        @meeting_sub.stop();
      @meeting_sub = new_meeting_sub;
    return

  @print_me = ->
    #preps
    $("body").append """<div class="print-meeting-mode-overlay"></div>"""
    $(".print-meeting-mode-overlay").html @html_representation()

    printAndClean = ->
      $("html").addClass "print-meeting"
      window.print()
      $(".print-meeting-mode-overlay").remove()
      $("html").removeClass "print-meeting"

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

  @delete_me = ->
    total_added_tasks = 0
    APP.meetings_manager_plugin.meetings_manager.meetings_tasks.find
      meeting_id: @data.meeting_id,
    ,
      fields:
        added_tasks: 1
    .forEach (meeting_task) ->
      if meeting_task.added_tasks?.length?
        total_added_tasks += meeting_task.added_tasks.length
      
      return
    msg = "Are you sure you want to delete this meeting?"
    if total_added_tasks > 0
      msg += " (#{total_added_tasks} #{if total_added_tasks == 1 then "task" else "tasks"} that was created in this meeting won't be deleted)"

    bootbox.confirm msg, (result) =>
      if result
        APP.meetings_manager_plugin.meetings_manager.deleteMeeting @data.meeting_id
        APP.meetings_manager_plugin.removeMeetingDialog()

      return
    
    return


  @plain_text_representation = ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: Template.currentData().meeting_id

    ret = "#{meeting.title}\n"
    if meeting.date?
      ret += "#{moment(meeting.date).format(JustdoHelpers.getUserPreferredDateFormat())} "
    
    if meeting.time?
      meeting_time = ""
      use_am_pm = Meteor.user().profile.use_am_pm
      if use_am_pm
        meeting_time = moment(meeting.time).format("h:mm A")
      else
        meeting_time = moment(meeting.time).format("HH:mm")

      ret += meeting_time

    if meeting.location?
      ret += "\n\nLocation: " + meeting.location
    
    ret += "\n\n"

    ret += "Attendees:\n\n"

    for user_id in meeting.users
      user = Meteor.users.findOne user_id
      ret += "* #{user.profile.first_name} #{user.profile.last_name}\n"
    
    if not _.isEmpty(meeting.other_attendees)
      ret += "* #{meeting.other_attendees}\n"

    ret+= "\n"
    ret += "Agenda:\n\n"
    tasks = _.sortBy meeting.tasks, 'task_order'
    for item in tasks
      ret += "##{item.seqId}: #{item.title}\n"

      meeting_task = APP.meetings_manager_plugin.meetings_manager.meetings_tasks.findOne
        _id: item.id

      if meeting_task?.added_tasks?.length > 0
        ret += "Child Tasks Added:\n"
        for task_added in meeting_task.added_tasks
          ret += "*#{task_added.title}, ##{task_added.seqId}\n"
          if (child_task_due_date = APP.collections.Tasks.findOne(task_added.task_id, {fields: due_date: 1}?.due_date))?
            ret += "Due date: #{moment(child_task_due_date).format(JustdoHelpers.getUserPreferredDateFormat())}\n"
          if (task_added.note?)
            note = JustdoHelpers.br2nl(task_added.note, {strip_trailing_br: true}).replace(/<[^>]*>/g, '')
            ret += "Notes: #{note}"

      if meeting_task?.note?
        note = JustdoHelpers.br2nl(meeting_task.note, {strip_trailing_br: true}).replace(/<[^>]*>/g, '')
        ret += "Notes:\n#{note}\n"
      ret += "\n"

    if meeting.note?
      note = JustdoHelpers.br2nl(meeting.note, {strip_trailing_br: true}).replace(/<[^>]*>/g, '')
      ret += "General Meeting Notes:\n\n#{note}\n"
    return ret

  @email_me = ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: Template.currentData().meeting_id

    emails=""
    for user_id in meeting.users
      user = Meteor.users.findOne user_id
      emails += "#{user.emails[0].address};"

    window.open("mailto:#{emails}?subject=#{encodeURIComponent(meeting.title)} - Meeting Notes&body=#{encodeURIComponent(@plain_text_representation())}");

Template.meetings_meeting_dialog.onRendered ->
  instance = this
  meeting_note_box = @$ "[name=\"note\"]"
  meeting_note_box.autosize()
  meeting = @meeting

  @$(".meetings_meeting-dialog").resizable
    handles: "e, w, s, n, se, sw, ne, nw"
    minWidth: 680

  @$(".meetings_meeting-dialog").draggable
    containment: ".global-wrapper"
    handle: ".meeting-dialog-header"

  # Make tasks sortable
  @$(".meeting-tasks-list").sortable
    handle: ".sort-task"
    stop: (event, ui) ->
      Session.set "updateTaskOrder", true

  @$(".meeting-time-wrapper").on 'shown.bs.dropdown', =>
    $meeting_time_input = @$(".meeting-time-input")
    if _.isEmpty($meeting_time_input.val())
      use_am_pm = Meteor.user().profile.use_am_pm
      if use_am_pm
        $meeting_time_input.val(moment().format("h:mm"))
      else
        $meeting_time_input.val(moment().format("HH:mm"))
    $meeting_time_input.select()
    $meeting_time_input.focus()
    return

  @autorun =>
    updateTaskOrder = Session.get "updateTaskOrder"
    if updateTaskOrder
      saveTasksOrder(instance)
      Session.set "updateTaskOrder", false

  @autorun =>
    # In order to be compatible with jquery-ui sortable, we need to manually add agenda tasks with the new order to the sortable
    # instead of rendering them directly in the html file

    meeting_id = Template.currentData().meeting_id
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: meeting_id
    ,
      fields:
        tasks: 1
    
    if not meeting?.tasks?
      return

    tasks = _.sortBy meeting.tasks, 'task_order'
    # tasks = _.filter tasks, _.identity

    $meeting_tasks_list = $(".meeting-tasks-list")
    $meeting_tasks_list.empty()

    _.forEach tasks, (item) ->
      Blaze.renderWithData(Template.meetings_dialog_task, item, $meeting_tasks_list[0])

    return

Template.meetings_meeting_dialog.helpers
  onSetDateRerender: ->
    tpl = Template.instance()
    Meteor.defer ->
      Tracker.autorun (comp) ->
        meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
          _id: tpl.data.meeting_id
        ,
          fields:
            date: 1
        
        if meeting?
          tpl.$(".meeting-date").datepicker
            "defaultDate": meeting.date
            "dateFormat": "yy-mm-dd"
          comp.stop()
      
      return

    return

  displayName: JustdoHelpers.displayName
  isAllowMeetingsDeletion: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: @meeting_id
    ,
      fields:
        organizer_id: 1
        status: 1

    return meeting.status == "draft" or 
      (not APP.modules.project_page.curProj()?.getProjectConfiguration()?.block_meetings_deletion and
        (Meteor.userId() == meeting.organizer_id or APP.modules.project_page.curProj()?.is_admin_rv.get()))

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
      _id: @meeting_id or @_id
    
    user_id = Meteor.userId()

    return meeting.status != "ended" and 
      (meeting.organizer_id == user_id or 
      (not meeting.locked and meeting.users? and user_id in meeting.users))

  mayEditFooter: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: @meeting_id
    
    user_id = Meteor.userId()

    return meeting.organizer_id == user_id or 
      (not meeting.locked and meeting.users and user_id in meeting.users)

  mayEditAgenda: ->
    meeting = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: @meeting_id

    user_id = Meteor.userId()

    return (meeting.status != "ended") and (meeting.status != "canceled") and
      (meeting.organizer_id == user_id or 
      (not meeting.locked and meeting.users and user_id in meeting.users))

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
          showSnackbar(err.message)

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

  rawdate: (date) ->
    date_format = Meteor.user().profile.date_format
    if(date?)
      return moment(date).format(date_format)
    return ""

  labelDate: (date) ->
    date_format = Meteor.user().profile.date_format
    if(date?)
      return moment(date).format(date_format)
    return "Set Date"

  # NEED TO CHANGE: We need to retrieve meeting time from Date !
  rawTime: (time) ->
    if not _.isEmpty(time)
      use_am_pm = Meteor.user().profile.use_am_pm
      if use_am_pm
        return moment(new Date(time)).format("h:mm A")
      else
        return moment(new Date(time)).format("HH:mm")
    return ""

  labelTime: (time) ->
    use_am_pm = Meteor.user().profile.use_am_pm
    if not _.isEmpty(time)
      if use_am_pm
        return moment(new Date(time)).format("h:mm A")
      else
        return moment(new Date(time)).format("HH:mm")
    return "Set Time"

  labelTimeHours: (time) ->
    use_am_pm = Meteor.user().profile.use_am_pm
    if (time?)
      if use_am_pm
        return moment(new Date(time)).format("h")
      else
        return moment(new Date(time)).format("HH")
    return "00"

  labelTimeMinutes: (time) ->
    if (time?)
      return moment(new Date(time)).format("mm")
    return "00"

  labelTimeAmPm: (time) ->
    use_am_pm = Meteor.user().profile.use_am_pm
    if (time?)
      return moment(new Date(time)).format("A")
    return "AM"

  useAmPm: ->
    user = Meteor.user()
    if user?
      return user.profile.use_am_pm

  # DEPRECATED
  # recentLocations: ->
  #   return Template.instance().data.locations


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

    if meeting.status == "ended" and !meeting.note?
      return false

    return true

  conversationClass: ->
    active_conversation_id = Session.get "active-conversation-id"
    if active_conversation_id? and active_conversation_id == @meeting_id
      return "active"

  isEditingLocation: -> Template.instance().is_editing_location.get()

  linkifyStr: (str) -> 
    if str?
      return linkifyStr str # linkify already escapes html entities, so don't worry about xss here.'
    return ""

Template.meetings_meeting_dialog.events
  "click .meeting-refresh": (e, tpl) ->
    tpl.refresh();
    return

  'click .meeting-print' : (e, tmpl) ->
    tmpl.print_me()

  'click .meeting-email': (e, tmpl) ->
    tmpl.email_me()

  'click .meeting-copy': (e, tmpl) ->
    tmpl.copy_me()
    showSnackbar("Meeting details copied to clipboard.")

  "click .meeting-delete": (e, tpl) ->
    tpl.delete_me()

    return

  "click .meeting-dialog-add-task, click .meeting-task-add-text": (e, tmpl) ->
    $task_no_input = tmpl.$(".meeting-task-add")
    $task_no_input.focus()
    return

  "documentChange .meeting-dialog-info, documentChange .meeting-note": (e, tmpl, doc, changes) ->
    tmpl.form.validate()
    if tmpl.form.isValid()

      if changes.title?
        if (changes.title == "")
          changes.title = "Untitled Meeting"

      if changes.date
        changes.date = moment(changes.date).toDate()

      if changes.time
        changes.time = moment(new Date(changes.time)).toDate()

      APP.meetings_manager_plugin.meetings_manager.updateMeetingMetadata doc._id, changes, (err) =>
        if err
          # Invalidate the form and show the user an error.
          tmpl.form.invalidate [{ error: err, name: "", message: "Update failed: " + err }]

          # Log an error using the logger
          APP.meetings_manager_plugin.logger.error err
          showSnackbar(err.message)

  "keydown .meeting-task-add": (e, tmpl) ->
    if e.which == 13
      $(e.currentTarget).trigger "change"
      # NOTE, Calling validate here clears out any existing errors so that if the
      # last call to validate created a server-inserted error, that error will be
      # hidden.
      addTaskToAgenda(tmpl)

    return

  "click .meeting-task-add-btn": (e, tmpl) ->
    addTaskToAgenda(tmpl)

    return



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
        showSnackbar(err.message)

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
        showSnackbar(err.message)


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
        showSnackbar(err.message)

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
        showSnackbar(err.message)


  'click .btn-end-meeting': (e, tmpl) ->
    # Clear out any existing errors related to the locked status
    doc = tmpl.form.doc()
    tmpl.form.validate("status")

    APP.meetings_manager_plugin.meetings_manager.updateMeetingStatus doc._id, "ended", (err) =>
      if err
        # Invalidate the form and show the user an error.
        tmpl.form.invalidate [{ error: err, name: "status", message: "Update status failed: " + err }]

        # Log an error using the logger
        APP.meetings_manager_plugin.logger.error err
        showSnackbar(err.message)

  "click .btn-cancel-meeting": (e, tmpl) ->
    JustdoSnackbar.show
      text: "Discard this meeting?"
      duration: 6000
      actionText: "No"
      showSecondButton: true
      secondButtonText: "Yes"
      onSecondButtonClick: =>
        # Clear out any existing errors related to the locked status
        doc = tmpl.form.doc()
        tmpl.form.validate("status")

        APP.meetings_manager_plugin.meetings_manager.updateMeetingStatus doc._id, "cancelled", (err) =>
          $(".meetings_meeting-dialog").remove()
          JustdoSnackbar.close()
          if err
            # Invalidate the form and show the user an error.
            tmpl.form.invalidate [{ error: err, name: "status", message: "Update status failed: " + err }]

            # Log an error using the logger
            APP.meetings_manager_plugin.logger.error err
            showSnackbar(err.message)
      onActionClick: =>
        JustdoSnackbar.close()
        return

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

  "keyup .meeting-time-input": (e, tpl) ->
    if e.key == "Escape"
      $(e.target).closest(".meeting-time-input").val "cancel"
      $(e.target).closest(".meeting-time-input").blur();
    else if e.key == "Enter"
      $(e.target).closest(".meeting-time-input").blur();
    
    return

  "blur .meeting-time-input": (e, tpl) ->
    $target = $(e.target).closest(".meeting-time-input")
    val = $target.val()
    if val == ""
      setMeetingTime tpl, null
    else
      date = moment(val, "HH:mmA").toDate()
      if not isNaN date.getTime()
        setMeetingTime tpl, date
    $target.val ""
    $target.closest(".meeting-time-wrapper").dropdown("toggle")
    return

  "click .meeting-time-am-pm": (e, tmpl) ->
    setMeetingHours(tmpl, 12)
    return

  "click .meeting-time-picker": (e, tmpl) ->
    e.stopPropagation()
    return

  "click .meeting-dialog-location-text": (e, tpl)->
    tpl.is_editing_location.set true
    Meteor.defer ->
      tpl.$(".meeting-dialog-location-input").focus()
      return
  
  "blur .meeting-dialog-location-input": (e, tpl) ->
    tpl.is_editing_location.set false
    APP.meetings_manager_plugin.meetings_manager.updateMeetingMetadata tpl.data.meeting_id,
      location: e.target.value
    return
  
  "focus .meeting-dialog-location-input": (e, tpl) ->
    $(e.target).data "old-value", e.target.value
    return

  "keydown .meeting-dialog-location-input": (e, tpl) ->
    if e.key == "Enter"
      e.target.blur()
    else if e.key == "Escape"
      e.target.value = $(e.target).data "old-value"
      e.target.blur()
    return
