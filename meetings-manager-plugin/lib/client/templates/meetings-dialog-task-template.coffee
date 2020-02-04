Forms.mixin Template.meetings_dialog_task

Template.meetings_dialog_task.onCreated ->
  @expanded = new ReactiveVar()
  @meeting_status = new ReactiveVar()

Template.meetings_dialog_task.onRendered ->
  task_note_box = @$("[name=\"task_note\"]")
  task_note_box.autosize()

  @update_notes = (data) =>
    own_note = _.findWhere (data.meeting_task?.user_notes || []), { user_id: Meteor.userId() }
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
      own_note_box.trigger('autosize.resize');

    private_note = data.private_note
    if private_note and private_note.note?
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

      private_note_box.val private_note.note
      private_note_box.trigger('autosize.resize');
  @autorun =>
    @update_notes Template.currentData()

  @autorun =>
    m = APP.meetings_manager_plugin.meetings_manager.meetings.findOne
      _id: Template.parentData().meeting_id
    @meeting_status.set m.status

Template.meetings_dialog_task.helpers
  allowAddingNotes: ->
    status = Template.instance().meeting_status.get()
    if (status == "adjourned" or status == "cancelled" or status == "draft")
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
    if (status == "adjourned" or status == "cancelled")
      return "readonly"
    return ""

  mayNotEditTaskNote: ->
    status = Template.instance().meeting_status.get()
    if (status == "in-progress")
      return false
    return true

  meetingId: ->
    return Template.instance().data.meeting._id

  taskId: ->
    return Template.instance().data.item.task_id

  onSaveTaskNote: ->
    tmpl = Template.instance()
    (changes) =>
      APP.meetings_manager_plugin.meetings_manager.setNoteForTask(
        tmpl.data.meeting._id,
        tmpl.data.item.task_id,
        {
          note: changes.content
          note_lock: changes.lock
        },
        (error) ->
          if error?
            tmpl.form.invalidate [{ error: error, message: error + '', name: "task_note" }]
      )

  lookupUser: (user_id) ->  Meteor.users.findOne user_id

  expandedClass: -> if not Template.instance().expanded.get() then "fa-chevron-right" else "fa-chevron-down"

  expanded: -> Template.instance().expanded.get()

  userNotes: () -> @meeting_task?.user_notes

  isSelf: (user_id) -> user_id == Meteor.userId()

  notesForUser: () -> @note

  detailsExcerpt: () ->

    if @meeting_task?.note
      result =
        is_summary: true
        note: @meeting_task.note
      return result

    for user_note in (@meeting_task?.user_notes || [])
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
        note: @private_note.note
      return result

    # XXX added tasks

  lookupTask: () ->
    APP.collections.Tasks.findOne @task_id


  hasOwnNote: () ->
    if _.findWhere (@meeting_task?.user_notes || []), { user_id: Meteor.userId() }
      return true
    return false

  hasPrivateNote: () ->
    if @private_note?
      return true
    return false

  hasNoAccessToTask: () ->
    if not @task?
      return true
    return false

  disabledIfOwnNote: () ->
    if _.findWhere (@meeting_task?.user_notes || []), { user_id: Meteor.userId() } then { disabled: true }

  disabledIfOwnPrivateNote: () -> if @private_note? then { disabled: true }

  disabledIfNoAccessToTask: () ->
    if not @task? then return { disabled: true }

  mayEdit: () ->
    return @meeting.organizer_id == Meteor.userId() or not @meeting.locked

  mayEditChildTask: () ->
    return Template.instance().data.meeting.status != "adjourned"

  index: () ->
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
      this.meeting._id,
      this.item.task_id,
      # This object would contain the note's initial fields, but we don't
      # currently provide an UI for that, so it's just empty for now.
      {},
      (error) ->
        if error?
          tmpl.form.invalidate [{ error: error, message: error + '', name: "user_notes.#{Meteor.userId()}" }]
    )

    tmpl.expanded.set true

  "click .btn-add-private-note": (e, tmpl) ->
    tmpl.form.validate()

    APP.meetings_manager_plugin.meetings_manager.addPrivateNoteToTask(
      this.meeting._id,
      this.item.task_id,
      # This object would contain the note's initial fields, but we don't
      # currently provide an UI for that, so it's just empty for now.
      {},
      (error) ->
        if error?
          tmpl.form.invalidate [{ error: error, message: error + '', name: "private_note" }]
    )

  "click .btn-add-task": (e, tmpl) ->
    tmpl.form.validate()
    APP.meetings_manager_plugin.meetings_manager.addSubTaskToTask @meeting._id, @item.task_id, title: ""

  "keyup textarea": (e, tmpl) ->

    refresh = (target) ->
        $(target).trigger 'change'

    name = e.currentTarget.name
    tmpl._throttled_refresh = tmpl._throttled_refresh || {}
    tmpl._throttled_refresh[name] = tmpl._throttled_refresh[name] || _.throttle refresh, 100

    Meteor.setTimeout =>
      tmpl._throttled_refresh[name](e.currentTarget)
    , 0

  "documentChange": (e, tmpl, doc, changes) ->
    e.preventDefault();

    tmpl.form.validate()

    user_id = Meteor.userId()
    user_note = changes["user_notes.#{user_id}"]

    if user_note?

      APP.meetings_manager_plugin.meetings_manager.setUserNoteForTask(
        tmpl.data.meeting._id,
        tmpl.data.item.task_id,
        {
          note: user_note
        },
        (error) ->
          if error?
            tmpl.form.invalidate [{ error: error, message: error + '', name: "user_notes.#{user_id}" }]
      )

    private_note = changes["private_note"]

    if private_note?

      APP.meetings_manager_plugin.meetings_manager.setPrivateNoteForTask(
        tmpl.data.meeting._id,
        tmpl.data.item.task_id,
        {
          note: private_note
        },
        (error) ->
          if error?
            tmpl.form.invalidate [{ error: error, message: error + '', name: "private_note" }]
      )

  "click .remove-task": (e, tmpl) ->
    meeting_status = tmpl.meeting_status.curValue

    if meeting_status == "draft"
      meeting_id = tmpl.data.meeting._id
      task_id = tmpl.data.meeting_task.task_id
      APP.meetings_manager_plugin.meetings_manager.removeTaskFromMeeting meeting_id, task_id

      Meteor.setTimeout =>
        Session.set "updateTaskOrder", true
      , 100
    else
      el = $(e.currentTarget)
      el.removeClass "remove-task"
      el.addClass "recover-task"
      task = el.closest ".meetings_dialog-task"
      task.addClass "remove"

      task_id = tmpl.data.meeting_task.task_id
      tasks_to_remove = Session.get "tasks_to_remove"
      tasks_to_remove.push task_id
      Session.set "tasks_to_remove", tasks_to_remove


  "click .recover-task": (e, tmpl) ->
    el = $(e.currentTarget)
    task_id = tmpl.data.meeting_task.task_id
    el.removeClass "recover-task"
    el.addClass "remove-task"
    task = el.closest ".meetings_dialog-task"
    task.removeClass "remove"

    task_id = tmpl.data.meeting_task.task_id
    tasks_to_remove = Session.get "tasks_to_remove"
    tasks_to_remove = _.without tasks_to_remove, task_id
    Session.set "tasks_to_remove", tasks_to_remove
