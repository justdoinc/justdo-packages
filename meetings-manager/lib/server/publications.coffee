_.extend MeetingsManager.prototype,
  _filterAddedTasks: (fields, user_id) ->
    if fields.added_tasks?.length > 0
      task_ids = _.map fields.added_tasks, (added_task) -> added_task.task_id
      accessible_task_ids = []
      APP.collections.Tasks.find
        _id:
          $in: task_ids
        users: user_id
      ,
        fields:
          _id: 1
      .forEach (task) ->
        accessible_task_ids.push task._id
        return
      
      fields.added_tasks = _.filter fields.added_tasks, (added_task) -> 
        return added_task.task_id in accessible_task_ids

    return fields

  _createSimpleObserver: (cursor, collection_name, sub) ->
    return cursor.observeChanges
      added: (id, fields) =>
        sub.added collection_name, id, fields

        return
      
      changed: (id, fields) =>
        sub.changed collection_name, id, fields
        
        return
      
      removed: (id) =>
        sub.removed collection_name, id
        return

  _setupPublications: ->
    self = @

    Meteor.publish "meetings_meeting", (meeting_id) ->
      sub = @
      user_id = @userId

      if not self.hasAccessToMeeting meeting_id, user_id
        throw self._error "meeting-not-found"

      cursor = self.meetings.find
        _id: meeting_id
      ,
        fields: undefined
          

      filterTasks = (meeting_id, fields, is_changed) ->
        if is_changed
          meeting = self.meetings.findOne meeting_id,
            fields: undefined
          _.extend meeting, fields
        else
          meeting = fields

        filtered_tasks = self.filterAccessableMeetingTasks meeting.tasks, user_id

        if (not user_id in meeting.users) and filtered_tasks.length == 0 
          return {
            _id: fields._id
          }
        else if (not user_id in meeting.users) and meeting.tasks?.length != filtered_tasks.length
          fields.note = null
        else if is_changed
          fields.note = meeting.note

        fields.tasks = filtered_tasks        

        return fields

      meetings_obs = cursor.observeChanges
        added: (id, fields) =>
          @added self.meetings._name, id, filterTasks(id, fields)

          return
        
        changed: (id, fields) =>
          if fields.tasks? or fields.users?
            fields = filterTasks(id, fields, true)
          @changed self.meetings._name, id, fields, true
          
          return
        
        removed: (id) =>
          @removed self.meetings._name, id
          return

      cursor = self.meetings_tasks.find
        meeting_id: meeting_id
      
      init = true
      meetings_tasks_obs = cursor.observeChanges
        added: (id, fields) =>
          if not init and self._isTaskMember fields.task_id, user_id
            sub.added self.meetings_tasks._name, id, self._filterAddedTasks(fields)

          return
        
        changed: (id, fields) =>
          if not init
            sub.changed self.meetings_tasks._name, id, self._filterAddedTasks(fields)
          
          return
        
        removed: (id) =>
          if not init
            sub.removed self.meetings_tasks._name, id

          return
      
      # init optimization
      meetings_tasks = cursor.fetch()
      meetings_tasks_ids = _.map meetings_tasks, (meeting_task) -> meeting_task.task_id
      accessible_task_ids = []
      APP.collections.Tasks.find
        _id:
          $in: meetings_tasks_ids
        users: user_id
      ,
        fields:
          _id: 1
      .forEach (task) ->
        accessible_task_ids.push task._id
        return

      for meeting_task in meetings_tasks
        if meeting_task.task_id in accessible_task_ids
          meeting_task_id = meeting_task._id
          delete meeting_task._id
          sub.added self.meetings_tasks._name, meeting_task_id, self._filterAddedTasks(meeting_task)
      init = false
        
      cursor = self.meetings_private_notes.find
        meeting_id: meeting_id
        user_id: user_id
      meetings_private_notes_obs = self._createSimpleObserver cursor, self.meetings_private_notes._name, sub

      @ready()

      @onStop ->
        meetings_obs.stop()
        meetings_tasks_obs.stop()
        meetings_private_notes_obs.stop()
        return
      
      return

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
      ,
        fields:
          _id: 1
          title: 1
          status: 1
          project_id: project_id
          date: 1

    Meteor.publish "meetings_meetings_for_task", (task_id) ->
      sub = @
      user_id = @userId
      check task_id, String
      check user_id, String

      task = self._requireTaskMember task_id, 
        _id: 1
        created_from_meeting_id: 1
      , user_id

      task_included_in_meeting_condition = {
        $or: [{
          "tasks.task_id": task_id,
          $or: [
            private:
              $ne: true
          ,
            users: user_id
          ]
        }]
      }

      meetings_selector = 
        $and: [{
          $or: [
            "status":
              $ne: "draft"
          ,
            "organizer_id": user_id
          ]
        }, task_included_in_meeting_condition]

      if task.created_from_meeting_id?
        task_included_in_meeting_condition.$or.push {
          _id: task.created_from_meeting_id
        }

      cursor = self.meetings.find meetings_selector,
        fields:
          _id: 1
          organizer_id: 1
          title: 1
          status: 1
          date: 1
          private: 1

      hideFieldsForAddedTasks = (fields) ->
        ret = {
          _id: fields._id
          meeting_id: fields.meeting_id
        }

        if fields.added_tasks
          ret.added_tasks = []
          for added_task in fields.added_tasks
            if added_task.task_id == task_id
              ret.added_tasks.push added_task

        return  ret
        
      meetings_tasks_obs = null
      meeting_ids = new Set()

      resetMeetingTasksObserver = () ->
        meeting_ids_arr = Array.from meeting_ids
        if meetings_tasks_obs?
          meetings_tasks_obs.stop()

        cursor = self.meetings_tasks.find
          meeting_id:
            $in: meeting_ids_arr
          task_id: task_id

        meetings_tasks_obs = cursor.observeChanges
          added: (id, fields) =>
            sub.added self.meetings_tasks._name, id, self._filterAddedTasks(fields, user_id)

            return
          
          changed: (id, fields) =>
            sub.changed self.meetings_tasks._name, id, self._filterAddedTasks(fields, user_id)
            
            return
          
          removed: (id) =>
            sub.removed self.meetings_tasks._name, id
            return

      is_init = true
      meetings_obs = cursor.observeChanges
        added: (id, fields) =>
          sub.added self.meetings._name, id, fields
          meeting_ids.add id
          if not is_init
            resetMeetingTasksObserver()
          return
        
        changed: (id, fields) =>
          sub.changed self.meetings._name, id, fields
          
          return
        
        removed: (id) =>
          sub.removed self.meetings._name, id
          meeting_ids.delete id
          if not is_init
            resetMeetingTasksObserver()

          return

      is_init = false
      resetMeetingTasksObserver()
      
      # meetings_private_notes
      cursor = self.meetings_private_notes.find
        task_id: task_id
        user_id: user_id
      meetings_private_notes_obs = self._createSimpleObserver cursor, self.meetings_private_notes._name, sub

      sub.onStop ->
        meetings_obs.stop()
        meetings_tasks_obs.stop()
        meetings_private_notes_obs.stop()
        return
        
      sub.ready()

      return