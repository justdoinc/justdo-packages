_.extend MeetingsManager.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      meetings_createMeeting: (fields) ->
        user_id = @userId
        self.createMeeting fields, user_id

      meetings_addUsersToMeeting: (meeting_id, user_ids) ->
        user_id = @userId
        self.addUsersToMeeting meeting_id, user_ids, user_id

      meetings_removeUsersFromMeeting: (meeting_id, user_ids) ->
        user_id = @userId
        self.removeUsersFromMeeting meeting_id, user_ids, user_id

      meetings_updateMeetingMetadata: (doc_id, fields) ->
        user_id = @userId
        self.updateMeetingMetadata doc_id, fields, user_id

      meetings_updateMeetingStatus: (doc_id, new_status) ->
        user_id = @userId
        self.updateMeetingStatus doc_id, new_status, user_id

      meetings_addTaskToMeeting: (meeting_id, task_fields) ->
        user_id = @userId
        self.addTaskToMeeting meeting_id, task_fields, user_id

      meetings_removeTaskFromMeeting: (meeting_id, task_id) ->
        user_id = @userId
        self.removeTaskFromMeeting meeting_id, task_id, user_id

      #obsolete
      meetings_moveMeetingTask: (meeting_id, task_id, move_direction) ->
        user_id = @userId
        self.moveMeetingTask meeting_id, task_id, move_direction, user_id

      meetings_setMeetingTaskOrder: (meeting_id, task_id, order) ->
        user_id = @userId
        self.setMeetingTaskOrder meeting_id, task_id, order, user_id

      meetings_addSubTaskToTask: (meeting_id, task_id, task_fields) ->
        user_id = @userId
        self.addSubTaskToTask meeting_id, task_id, task_fields, user_id

      meetings_saveSubTaskSubject: (meeting_id, task_id, added_task_id, added_task_subject) ->
        user_id = @userId
        self.saveSubTaskSubject meeting_id, task_id, added_task_id, added_task_subject, user_id

      meetings_addUserNoteToTask: (meeting_id, task_id, note_fields) ->
        user_id = @userId
        self.addUserNoteToTask meeting_id, task_id, note_fields, user_id

      meetings_setUserNoteForTask: (meeting_id, task_id, note_fields) ->
        user_id = @userId
        self.setUserNoteForTask meeting_id, task_id, note_fields, user_id

      meetings_setNoteForTask: (meeting_id, task_id, note_fields) ->
        user_id = @userId
        self.setNoteForTask meeting_id, task_id, note_fields, user_id

      meetings_addPrivateNoteToTask: (meeting_id, task_id, note_fields) ->
        user_id = @userId
        self.addPrivateNoteToTask meeting_id, task_id, note_fields, user_id

      meetings_setPrivateNoteForTask: (meeting_id, task_id, note_fields) ->
        user_id = @userId
        self.setPrivateNoteForTask meeting_id, task_id, note_fields, user_id

      meetings_updateMeetingLock: (meeting_id, locked) ->
        user_id = @userId
        self.updateMeetingLock meeting_id, locked, user_id

      meetings_updateMeetingPrivacy: (meeting_id, isPrivate) ->
        user_id = @userId
        self.updateMeetingPrivacy meeting_id, isPrivate, user_id


    return
