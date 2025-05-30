meetings_manager = null

Template.meeting_container.onCreated ->
  meetings_manager = APP.meetings_manager_plugin.meetings_manager
  @expanded = new ReactiveVar(new Set())

  meeting_id = @data._id
  @meeting_sub = APP.meetings_manager_plugin.meetings_manager.subscribeToMeeting meeting_id

  return

Template.meeting_container.onDestroyed ->
  @meeting_sub.stop()

  return

Template.meeting_container.helpers

  notes: ->
    
    task_id = APP.modules.project_page.activeItemId()
    meeting_id = @_id
    notes = []

    private_notes = meetings_manager.meetings_private_notes.find({ task_id: task_id, meeting_id: meeting_id }).fetch()

    _.each private_notes, (private_note) =>
      if private_note.note?
        notes.push
          note: private_note.note
          meeting_id: private_note.meeting_id
          user_id: private_note.user_id
          updatedAt: private_note.updatedAt
          is_private_note: true

    meeting_notes = meetings_manager.meetings_tasks.find({ task_id: task_id, meeting_id: meeting_id }).fetch()

    _.each meeting_notes, (note) =>

      _.each note.user_notes, (user_note) =>
        if user_note.note?
          notes.push
            note: user_note.note
            meeting_id: note.meeting_id
            user_id: user_note.user_id
            updatedAt: user_note.updatedAt

      if note.note?
        notes.push
          note: note.note
          meeting_id: note.meeting_id
          user_id: null
          updatedAt: note.updatedAt

    return notes

  addedTasks: ->
    task_id = APP.modules.project_page.activeItemId()
    meeting_id = @_id
    added_tasks = meetings_manager.meetings_tasks.find
      meeting_id: meeting_id
      $or: [
        {task_id: task_id},
        {"added_tasks.task_id": task_id}
      ]
    .fetch()

    added_tasks = {
      "exist": added_tasks[0]?.added_tasks.length,
      "tasks": added_tasks[0]?.added_tasks
    }

    return added_tasks

  taskNotFound: ->
    if not (JD.collections.Tasks.findOne({_id:@task_id}))
      return true
    return false

  getTaskTitle: ->
    task_obj = JD.collections.Tasks.findOne @task_id,
      fields:
        title: 1
    
    if task_obj?
      return task_obj.title
    
    return "(Task not found)"

  lookupUser: (user_id) -> Meteor.users.findOne user_id

  isOwnNote: () -> @user_id == Meteor.userId()

  isPrivateNote: () -> @is_private_note == true

  expanded: () ->
    z = Template.instance().expanded.get()
    return z.has @_id


Template.meeting_container.events

  "click .meeting-all-notes": (e, tmpl) ->
    APP.meetings_manager_plugin.renderMeetingDialog @_id

  "click .meeting-container": (e, tmpl) ->
    z = tmpl.expanded.get()
    if (z.has(@_id))
      z.delete(@_id)
      tmpl.$(".meeting-container").removeClass "expanded"
    else
      z.add(@_id)
      tmpl.$(".meeting-container").addClass "expanded"
    tmpl.expanded.set z
  
  "click .info-subtask": (e, tpl) ->
    task_id = $(e.target).closest(".info-subtask").data("task-id")

    gcm = APP.modules.project_page.getCurrentGcm()

    gcm.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(task_id)
    
    return false
