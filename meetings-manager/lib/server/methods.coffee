_.extend MeetingsManager.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      meetings_createMeeting: (fields) ->
        user_id = @userId
        await self.createMeetingAsync fields, user_id

      meetings_addUsersToMeeting: (meeting_id, user_ids) ->
        user_id = @userId
        await self.addUsersToMeetingAsync meeting_id, user_ids, user_id

      meetings_removeUsersFromMeeting: (meeting_id, user_ids) ->
        user_id = @userId
        await self.removeUsersFromMeetingAsync meeting_id, user_ids, user_id

      meetings_updateMeetingMetadata: (doc_id, fields) ->
        user_id = @userId
        await self.updateMeetingMetadataAsync doc_id, fields, user_id

      meetings_updateMeetingStatus: (doc_id, new_status) ->
        user_id = @userId
        await self.updateMeetingStatusAsync doc_id, new_status, user_id

      meetings_addTaskToMeeting: (meeting_id, task_fields) ->
        user_id = @userId
        await self.addTaskToMeetingAsync meeting_id, task_fields, user_id

      meetings_removeTaskFromMeeting: (meeting_id, task_id) ->
        user_id = @userId
        await self.removeTaskFromMeetingAsync meeting_id, task_id, user_id

      meetings_removeSubtaskFromMeeting: (meeting_id, parent_task_id, subtask_id) ->
        user_id = @userId
        await self.removeSubtaskFromMeetingAsync meeting_id, parent_task_id, subtask_id, user_id

      #obsolete
      meetings_moveMeetingTask: (meeting_id, task_id, move_direction) ->
        user_id = @userId
        await self.moveMeetingTaskAsync meeting_id, task_id, move_direction, user_id

      meetings_setMeetingTaskOrder: (meeting_id, task_id, order) ->
        user_id = @userId
        await self.setMeetingTaskOrderAsync meeting_id, task_id, order, user_id

      meetings_addSubTaskToTask: (meeting_id, task_id, task_fields) ->
        user_id = @userId
        await self.addSubTaskToTaskAsync meeting_id, task_id, task_fields, user_id

      meetings_saveSubTaskSubject: (meeting_id, task_id, added_task_id, added_task_subject) ->
        user_id = @userId
        await self.saveSubTaskSubjectAsync meeting_id, task_id, added_task_id, added_task_subject, user_id

      meetings_addUserNoteToTask: (meeting_id, task_id, note_fields) ->
        user_id = @userId
        await self.addUserNoteToTaskAsync meeting_id, task_id, note_fields, user_id

      meetings_setUserNoteForTask: (meeting_id, task_id, note_fields) ->
        user_id = @userId
        await self.setUserNoteForTaskAsync meeting_id, task_id, note_fields, user_id

      meetings_setNoteForTask: (meeting_id, task_id, note_fields) ->
        user_id = @userId
        await self.setNoteForTaskAsync meeting_id, task_id, note_fields, user_id

      meetings_addPrivateNoteToTask: (meeting_id, task_id, note_fields) ->
        user_id = @userId
        await self.addPrivateNoteToTaskAsync meeting_id, task_id, note_fields, user_id

      meetings_setPrivateNoteForTask: (meeting_id, task_id, note_fields) ->
        user_id = @userId
        await self.setPrivateNoteForTaskAsync meeting_id, task_id, note_fields, user_id

      meetings_updateMeetingLock: (meeting_id, locked) ->
        user_id = @userId
        await self.updateMeetingLockAsync meeting_id, locked, user_id

      meetings_updateMeetingPrivacy: (meeting_id, isPrivate) ->
        user_id = @userId
        await self.updateMeetingPrivacyAsync meeting_id, isPrivate, user_id

      meetings_deleteMeeting: (meeting_id) ->
        user_id = @userId
        await self.deleteMeetingAsync meeting_id, user_id
        
        return

      meetings_updateAddedTaskNote: (meeting_task_id, added_task_id, changes) ->
        user_id = @userId
        await self.updateAddedTaskNoteAsync meeting_task_id, added_task_id, changes, user_id
        
        return
      
      meetings_recalTaskMeetingsCache: (task_id) ->
        user_id = @userId
        
        task = await self._requireTaskMemberAsync task_id, {_id: 1}, user_id

        await self.recalTaskMeetingsCacheAsync task_id

        return

    return
