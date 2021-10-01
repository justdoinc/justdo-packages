Forms.mixin Template.meetings_dialog_task

Template.meetings_dialog_task.onCreated ->
  @expanded = new ReactiveVar()
  @meeting_status = new ReactiveVar()

  @autorun =>
    # In order to solve the jquery-ui sortable compatibility issue, this template cannot reply on the template data passed by its parent anymore
    # However, the legacy code in this template is relying on the template data(Template.currentData(), this, etc.) too heavily.
    # Thus, this autorun is created as a hack to update the Template.currentData() by itself.
    item = Template.instance().data
    if item.item?
      item = item.item
    meeting_task = APP.meetings_manager_plugin.meetings_manager.meetings_tasks.findOne
      _id: item.id
    data =
      item: item
      meeting: Tracker.nonreactive => APP.meetings_manager_plugin.meetings_manager.meetings.findOne(meeting_task?.meeting_id)
      task: APP.collections.Tasks.findOne
        _id: item.task_id
      meeting_task: meeting_task
      private_note: APP.meetings_manager_plugin.meetings_manager.meetings_private_notes.findOne
        meeting_id: meeting_task?.meeting_id
        task_id: item.task_id
      task_order: item.task_order

    Template.instance().data = data
    Blaze.getView("with").dataVar.set(data)

    return

  return

Template.meetings_dialog_task.onRendered ->
  task_note_box = @$("[name=\"task_note\"]")
  task_note_box.autosize()

  @update_notes = (data) =>
    own_note = _.findWhere (data.meeting_task?.user_notes or []), {user_id: Meteor.userId()}
    if own_note and own_note.note?
      own_note_box = @$("[name=\"user_notes.#{Meteor.userId()}\"]")
      own_note_box.autosize()
      if own_note_box.length == 0
        Meteor.setTimeout =>
          @update_notes(data)
        , 10

        return

      if own_note_box.is(":focus")
        own_note_box.on "blur", =>
          @update_notes(data)
        return

      own_note_box.val own_note.note
      own_note_box.trigger("autosize.resize")

    private_note = data.private_note
    if private_note and private_note?.note?
      private_note_box = @$("[name=\"private_note\"]")
      private_note_box.autosize()
      if private_note_box.length == 0
        Meteor.setTimeout =>
          @update_notes(data)
        , 10
        return

      if private_note_box.is(":focus")
        private_note_box.on "blur", =>
          @update_notes(data)
        return

      private_note_box.val private_note?.note
      private_note_box.trigger("autosize.resize")
  @autorun =>
    @update_notes Template.currentData()

  @autorun =>
    m = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: Template.currentData().meeting?._id
    @meeting_status.set m?.status
    return

  return

Template.meetings_dialog_task.helpers
  isAttendee: ->
    return Template.instance().data.meeting?.users and Meteor.userId() in Template.instance().data.meeting?.users

  allowAddingNotes: ->
    status = Template.instance().meeting_status.get()
    if (status == "ended" or status == "cancelled" or status == "draft")
      return false
    return true

  allowSortingNotes: ->
    status = Template.instance().meeting_status.get()
    if (status == "pending" or status == "in-progress" or status == "draft")
      return true
    return false

  displayTaskNote: ->
    status = Template.instance().meeting_status.get()
    if (status == "draft" or status == "pending")
      return false
    return true

  isReadOnly: ->
    status = Template.instance().meeting_status.get()
    if (status == "ended" or status == "cancelled")
      return "readonly"
    return ""

  mayNotEditTaskNote: ->
    status = Template.instance().meeting_status.get()
    if (status == "in-progress")
      return false
    return true

  meetingId: ->
    return Template.instance().data.meeting?._id

  taskId: ->
    return Template.instance().data.item.task_id

  meetingTaskId: ->
    return Template.instance().data.meeting_task?._id

  onSaveTaskNote: ->
    tmpl = Template.instance()
    return (changes) =>
      APP.meetings_manager_plugin.meetings_manager.setNoteForTask(
        tmpl.data.meeting?._id,
        tmpl.data.item.task_id,
        {
          note: changes.content
          note_lock: changes.lock
        },
        (error) ->
          if error?
            tmpl.form.invalidate [{error: error, message: error + "", name: "task_note"}]
      )

  lookupUser: (user_id) ->  Meteor.users.findOne user_id

  expandedClass: -> if not Template.instance().expanded.get() then "fa-chevron-right" else "fa-chevron-down"

  expanded: -> Template.instance().expanded.get()

  userNotes: -> @meeting_task?.user_notes

  isSelf: (user_id) -> user_id == Meteor.userId()

  notesForUser: -> @note

  detailsExcerpt: ->

    if @meeting_task?.note
      result =
        is_summary: true
        note: @meeting_task?.note
      return result

    for user_note in (@meeting_task?.user_notes or [])
      if user_note.note?
        result =
          is_note: true
          note: user_note.note
          user_id: user_note.user_id
        return result

    if @private_note?.note?
      result =
        is_note: true
        is_private_note: true
        note: @private_note?.note
      return result

    # XXX added tasks

  lookupTask: (added_task) ->
    task = APP.collections.Tasks.findOne added_task.task_id
    task.meeting_note = added_task.note
    task.meeting_note_lock = added_task.note_lock
    return task

  hasOwnNote: ->
    if _.findWhere (@meeting_task?.user_notes or []), {user_id: Meteor.userId()}
      return true
    return false

  hasPrivateNote: ->
    if @private_note?
      return true
    return false

  hasNoAccessToTask: ->
    if not @task?
      return true
    return false

  disabledIfOwnNote: ->
    if _.findWhere (@meeting_task?.user_notes or []), {user_id: Meteor.userId()} then {disabled: true}

  disabledIfOwnPrivateNote: -> if @private_note? then {disabled: true}

  disabledIfNoAccessToTask: ->
    if not @task? then return {disabled: true}

  mayEdit: ->
    return @meeting?.organizer_id == Meteor.userId() or not @meeting?.locked

  mayEditChildTask: ->
    return Template.instance().data.meeting?.status != "ended"

  index: ->
    return (@item.task_order + 1)

Template.meetings_dialog_task.events
#  "click .meetings_dialog-task, click .sub-task": (e, tmpl) ->
#    if e.isDefaultPrevented()
#      return
#
#    e.preventDefault()
#
#    task_id = if $(e.currentTarget).is(".meetings_dialog-task") then @item.task_id else @_id
#
#    # TODO trigger selected task
#    console.log task_id

  "click .btn-add-note": (e, tmpl) ->
    tmpl.form.validate()

    APP.meetings_manager_plugin.meetings_manager.addUserNoteToTask(
      @meeting?._id,
      @item.task_id,
      # This object would contain the note's initial fields, but we don't
      # currently provide an UI for that, so it's just empty for now.
      {},
      (error) ->
        if error?
          tmpl.form.invalidate [{error: error, message: error + "", name: "user_notes.#{Meteor.userId()}"}]
    )

    tmpl.expanded.set true

    return

  "click .btn-add-private-note": (e, tmpl) ->
    tmpl.form.validate()

    APP.meetings_manager_plugin.meetings_manager.addPrivateNoteToTask(
      @meeting?._id,
      @item.task_id,
      # This object would contain the note's initial fields, but we don't
      # currently provide an UI for that, so it's just empty for now.
      {},
      (error) ->
        if error?
          tmpl.form.invalidate [{error: error, message: error + "", name: "private_note"}]
    )

    return

  "click .btn-add-task": (e, tmpl) ->
    tmpl.form.validate()
    APP.meetings_manager_plugin.meetings_manager.addSubTaskToTask @meeting?._id, @item.task_id, title: "", (err, new_task_id) =>
      if not err?
        Meteor.defer ->
          $("[data-task-id=\"#{new_task_id}\"].task-subject-box").focus()
    return

  "keyup textarea": (e, tmpl) ->
    refresh = (target) ->
      $(target).trigger "change"

    name = e.currentTarget.name
    tmpl._throttled_refresh = tmpl._throttled_refresh or {}
    tmpl._throttled_refresh[name] = tmpl._throttled_refresh[name] or _.throttle refresh, 100

    Meteor.setTimeout =>
      tmpl._throttled_refresh[name](e.currentTarget)
    , 0

    return

  "documentChange": (e, tmpl, doc, changes) ->
    e.preventDefault()

    tmpl.form.validate()

    user_id = Meteor.userId()
    user_note = changes["user_notes.#{user_id}"]

    if user_note?
      APP.meetings_manager_plugin.meetings_manager.setUserNoteForTask(
        tmpl.data.meeting?._id,
        tmpl.data.item.task_id,
        {
          note: user_note
        },
        (error) ->
          if error?
            tmpl.form.invalidate [{error: error, message: error + "", name: "user_notes.#{user_id}"}]
      )

    private_note = changes["private_note"]

    if private_note?
      APP.meetings_manager_plugin.meetings_manager.setPrivateNoteForTask(
        tmpl.data.meeting?._id,
        tmpl.data.item.task_id,
        {
          note: private_note
        },
        (error) ->
          if error?
            tmpl.form.invalidate [{error: error, message: error + "", name: "private_note"}]
      )

    return

  "click .remove-task": (e, tmpl) ->
    meeting_id = tmpl.data.meeting?._id
    task_id = tmpl.data.meeting_task?.task_id
    APP.meetings_manager_plugin.meetings_manager.removeTaskFromMeeting meeting_id, task_id

    Meteor.setTimeout =>
      Session.set "updateTaskOrder", true
    , 100

    return

  "click .dialog-agenda-task": (e, tpl) ->
    e.preventDefault()
    if (task_id = tpl.data?.meeting_task?.task_id)?
      gcm = APP.modules.project_page.getCurrentGcm()
      gcm.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(task_id)

    return
