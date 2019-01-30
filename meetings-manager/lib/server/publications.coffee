_.extend MeetingsManager.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "meetings_meetings_list", (project_id) ->
      user_id = @userId

      self._requireProjectMember project_id, user_id

      return self.meetings.find
        $or: [
          "users": user_id
          "status":
            $ne: "draft"
        ,
          "organizer_id": user_id
        ]
        "project_id": project_id

    Meteor.publish "meetings_notes_for_meeting", (meeting_id) ->
      user_id = @userId

      self._requireMeetingMember meeting_id, false, user_id

      return self.meetings_tasks.find
        meeting_id: meeting_id

    Meteor.publish "meetings_private_note_for_meeting", (meeting_id) ->
      user_id = @userId

      # XXX it's arguable whether this check is needed, since we only
      # show user's their own private notes.
      self._requireMeetingMember meeting_id, false, user_id

      return self.meetings_private_notes.find
        meeting_id: meeting_id
        user_id: user_id

    Meteor.publish "meetings_meetings_for_task", (task_id) ->
      user_id = @userId

      self._requireTaskMember task_id, user_id

      return self.meetings.find
        "tasks.task_id": task_id
        $or: [
          private:
            $ne: true
        ,
          users: user_id
        ]
      ,
        fields:
          organizer_id: 1
          title: 1
          status: 1
          date: 1

    Meteor.publish "meetings_notes_for_task", (task_id, meeting_id) ->
      user_id = @userId

      self._requireTaskMember task_id, user_id

      self._requireProjectMemberOrPublic meeting_id, user_id

      return self.meetings_tasks.find
        task_id: task_id
        meeting_id: meeting_id

    Meteor.publish "meetings_private_note_for_task", (task_id) ->
      user_id = @userId

      # XXX it's arguable whether this check is needed, since we only
      # show user's their own private notes.
      self._requireTaskMember task_id, user_id

      return self.meetings_private_notes.find
        task_id: task_id
        user_id: user_id
