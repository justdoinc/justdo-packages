_.extend MeetingsManager.prototype,
  deleteMeeting: (meeting_id, cb) ->
    Meteor.call "meetings_deleteMeeting", meeting_id, cb

    return
  
  updateAddedTaskNote: (meeting_task_id, added_task_id, changes, cb) ->
    Meteor.call "meetings_updateAddedTaskNote", meeting_task_id, added_task_id, changes, cb

    return