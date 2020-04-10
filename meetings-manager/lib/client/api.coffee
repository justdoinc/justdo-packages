_.extend MeetingsManager.prototype,
  createMeeting: (fields, cb) ->
    Meteor.call "meetings_createMeeting", fields, cb

  addUsersToMeeting: (meeting_id, user_ids, cb) ->
    Meteor.call "meetings_addUsersToMeeting", meeting_id, user_ids, cb

  removeUsersFromMeeting: (meeting_id, user_ids, cb) ->
    Meteor.call "meetings_removeUsersFromMeeting", meeting_id, user_ids, cb

  updateMeetingMetadata: (meeting_id, fields, cb) ->
    # XXX We should validate the changes here so that errors can come back faster.
    Meteor.call "meetings_updateMeetingMetadata", meeting_id, fields, cb

  updateMeetingStatus: (meeting_id, new_status, cb) ->
    # XXX We should validate the changes here so that errors can come back faster.
    Meteor.call "meetings_updateMeetingStatus", meeting_id, new_status, cb

  addTaskToMeeting: (meeting_id, task_fields, cb) ->
    Meteor.call "meetings_addTaskToMeeting", meeting_id, task_fields, cb

  removeTaskFromMeeting: (meeting_id, task_id, cb) ->
    Meteor.call "meetings_removeTaskFromMeeting", meeting_id, task_id, cb

  removeSubtaskFromMeeting: (meeting_id, parent_task_id, subtask_id, cb) ->
    Meteor.call "meetings_removeSubtaskFromMeeting", meeting_id, parent_task_id, subtask_id, cb


# obsolete
  moveMeetingTask: (meeting_id, task_id, move_direction, cb) ->

    Meteor.call "meetings_moveMeetingTask", meeting_id, task_id, move_direction, cb

  # the internal order of the agenda is set by the task_order field of the task
  # within the meetings.tasks array.
  setMeetingTaskOrder: (meeting_id, task_id, order, cb) ->
    Meteor.call "meetings_setMeetingTaskOrder", meeting_id, task_id, order, cb

  addSubTaskToTask: (meeting_id, task_id, task_fields, cb) ->

    Meteor.call "meetings_addSubTaskToTask", meeting_id, task_id, task_fields, cb

  saveSubTaskSubject: (meeting_id, task_id, added_task_id, added_task_subject, cb) ->

    Meteor.call "meetings_saveSubTaskSubject", meeting_id, task_id, added_task_id, added_task_subject, cb

  addUserNoteToTask: (meeting_id, task_id, note_fields, cb) ->

    Meteor.call "meetings_addUserNoteToTask", meeting_id, task_id, note_fields, cb

  setUserNoteForTask: (meeting_id, task_id, note_fields, cb) ->

    Meteor.call "meetings_setUserNoteForTask", meeting_id, task_id, note_fields, cb

  setNoteForTask: (meeting_id, task_id, note_fields, cb) ->

    Meteor.call "meetings_setNoteForTask", meeting_id, task_id, note_fields, cb

  addPrivateNoteToTask: (meeting_id, task_id, note_fields, cb) ->

    Meteor.call "meetings_addPrivateNoteToTask", meeting_id, task_id, note_fields, cb

  setPrivateNoteForTask: (meeting_id, task_id, note_fields, cb) ->

    Meteor.call "meetings_setPrivateNoteForTask", meeting_id, task_id, note_fields, cb

  updateMeetingLock: (meeting_id, locked, cb) ->

    Meteor.call "meetings_updateMeetingLock", meeting_id, locked, cb

  updateMeetingPrivacy: (meeting_id, isPrivate, cb) ->

    Meteor.call "meetings_updateMeetingPrivacy", meeting_id, isPrivate, cb

  subscribeToMeetingsList: (project_id) ->

    Meteor.subscribe "meetings_meetings_list", project_id

  subscribeToNotesForMeeting: (meeting_id) ->

    Meteor.subscribe "meetings_notes_for_meeting", meeting_id

  subscribeToPrivateNotesForMeeting: (meeting_id) ->

    Meteor.subscribe "meetings_private_note_for_meeting", meeting_id

  subscribeToMeetingsForTask: (task_id) ->

    Meteor.subscribe "meetings_meetings_for_task", task_id

  subscribeToNotesForTask: (task_id) ->

    Tracker.autorun =>
      _.each @meetings.find().fetch(), (meeting) =>
        Meteor.subscribe "meetings_notes_for_task", task_id, meeting._id

  subscribeToPrivateNotesForTask: (task_id) ->

    Meteor.subscribe "meetings_private_note_for_task", task_id

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
