_.extend MeetingsManager.prototype,
  createMeetingAsync: (fields, user_id) ->
    @_requireObject fields, "fields should be an object"
    await @_requireProjectMemberAsync fields.project_id, user_id

    fields.organizer_id = user_id
    fields.users = [user_id]

    await @meetings.insertAsync fields

  addUsersToMeetingAsync: (meeting_id, user_ids, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"

    meeting = await @_requireMeetingMemberAsync meeting_id, true, user_id

    for user in user_ids
      await @_requireProjectMemberAsync meeting.project_id, user

    await @meetings.updateAsync
      _id: meeting_id
    ,
      $addToSet:
        users:
          $each: user_ids

  removeUsersFromMeetingAsync: (meeting_id, user_ids, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"

    meeting = await @_requireMeetingMemberAsync meeting_id, true, user_id

    for user in user_ids
      # Don't allow users to remove the meeting organizer
      if user == meeting.organizer_id
        throw @_error "invalid-request", "You can't remove the organizer from a meeting"

    await @meetings.updateAsync
      _id: meeting_id
    ,
      $pullAll:
        users: user_ids


  updateMeetingMetadataAsync: (meeting_id, fields, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"
    @_requireObject fields, "fields should be an object"
    await @_requireMeetingMemberAsync meeting_id, true, user_id
    @_requireValidatedPartialObject fields, @meeting_metadata_schema
    await @meetings.updateAsync { _id: meeting_id }, { $set: fields }


  updateMeetingStatusAsync: (meeting_id, new_status, user_id) ->
    self = @
    @_requireString meeting_id, "meeting_id should be a string"
    @_requireString new_status, "new_status should be a string"
    meeting = await @_requireMeetingMemberAsync meeting_id, true, user_id

    update =
      $set:
        status: new_status

    # XXX which other status changes may only be performed by the organizer?
    if meeting.status == "draft"
      await @_requireMeetingOrganizerAsync meeting_id, user_id

    if new_status == "in-progress"
      update.$push =
        start:
          user_id: user_id
          date: new Date()

    if new_status == "ended"
      update.$push =
        end:
          user_id: user_id
          date: new Date()

    await @meetings.updateAsync { _id: meeting_id }, update
    meeting_tasks = await @meetings_tasks.find(
      meeting_id: meeting_id
    ,
      fields:
        task_id: 1
    ).forEachAsync (meeting_task) ->
      await self.recalTaskMeetingsCacheAsync(meeting_task.task_id)

    return
    
  addTaskToMeetingAsync: (meeting_id, task_fields, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"
    @_requireObject task_fields, "fields should be an object"

    meeting = await @_requireMeetingMemberAsync meeting_id, true, user_id
    task = await @_requireTaskFromSearchAsync task_fields, meeting.project_id, user_id

    @_requireTaskIsUnique meeting.tasks, task._id

    meeting_task_id = await @meetings_tasks.insertAsync
      task_id: task._id
      meeting_id: meeting_id

    await @meetings.updateAsync
      _id: meeting_id
    ,
      $push:
        "tasks":
          id: meeting_task_id
          task_id: task._id
          seqId: task.seqId
          title: task.title
          added_by_user: user_id
          added_at: new Date
          task_order: meeting.tasks.length

    await @recalTaskMeetingsCacheAsync(task._id)

    return meeting_task_id

  removeSubtaskFromMeetingAsync: (meeting_id, parent_task_id, subtask_id, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"
    @_requireString parent_task_id, "parent_task_id should be a string"
    @_requireString subtask_id, "subtask_id should be a string"
    meeting = await @_requireMeetingMemberAsync meeting_id, true, user_id

    query =
      meeting_id: meeting_id
      task_id: parent_task_id
    op =
      $pull:
        added_tasks:
          task_id: subtask_id
    await @meetings_tasks.updateAsync query, op

    APP.projects._grid_data_com.removeParent("/#{parent_task_id}/#{subtask_id}/", user_id)

    return true


  removeTaskFromMeetingAsync: (meeting_id, task_id, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"
    @_requireString task_id, "task_id should be a string"

    meeting = await @_requireMeetingMemberAsync meeting_id, true, user_id

    await @meetings_tasks.removeAsync
      meeting_id: meeting_id
      task_id: task_id

    await @meetings_private_notes.removeAsync
      meeting_id: meeting_id
      task_id: task_id

    await @meetings.updateAsync
      _id: meeting_id
    ,
      $pull:
        "tasks":
          task_id: task_id

    await @recalTaskMeetingsCacheAsync(task_id)
        
    return true


  setMeetingTaskOrderAsync: (meeting_id, task_id, order, user_id) ->


    @_requireString meeting_id, "meeting_id should be a string"
    @_requireString task_id, "task_id should be a string"

    meeting = await @_requireMeetingMemberAsync meeting_id, true, user_id
    meeting_task = _.findWhere meeting.tasks, { task_id: task_id }

    if not meeting_task?
      throw @_error "invalid-request", "Task is not part of meeting."

    await @meetings.updateAsync
        _id: meeting_id
        "tasks.task_id": task_id
    ,
      $set: {"tasks.$.task_order": order}

    return true

  recalTaskMeetingsCacheAsync: (task_id) ->
    self = @
    
    all_meeting_ids = await self.meetings_tasks.find(
      task_id: task_id
    ,
      fields:
        meeting_id: 1
    ).mapAsync (meeting_task) ->
      return meeting_task.meeting_id

    meeting_ids = await self.meetings.find(
      _id:
        $in: all_meeting_ids
      status:
        $nin: ["draft"]
    ,
      fields:
        _id: 1
        status: 1
    ).mapAsync (meeting) ->
      return meeting._id

    await APP.collections.Tasks.updateAsync task_id,
      $set:
        [MeetingsManagerPlugin.task_meetings_cache_field_id]: meeting_ids

    return

# obsolete:
  moveMeetingTaskAsync: (meeting_id, task_id, move_direction, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"
    @_requireString task_id, "task_id should be a string"

    meeting = await @_requireMeetingMemberAsync meeting_id, true, user_id
    meeting_task = _.findWhere meeting.tasks, { task_id: task_id }

    if not meeting_task?
      throw @_error "invalid-request", "Task is not part of meeting."

    if move_direction != 1 and move_direction != -1
      throw @_error "invalid-request", "Move direction out of range"

    # This is all super convoluted because there's no way in mongo to just move
    # an item in the array. Instead we're recomputing the sort index and updating
    # that. The client will then sort by task_order.

    tasks = _.sortBy meeting.tasks.concat(), 'task_order'
    task_to_reorder = _.findWhere tasks, { task_id: task_id }
    task_index = tasks.indexOf task_to_reorder

    if move_direction == -1 and task_index == 0
      throw @_error "invalid-request", "Move direction out of range"

    if move_direction == 1 and task_index == tasks.length - 1
      throw @_error "invalid-request", "Move direction out of range"

    tasks.splice task_index, 1
    tasks.splice task_index + move_direction, 0, task_to_reorder

    update = {}
    _.each meeting.tasks, (task, i) =>
      update["tasks.#{i}.task_order"] = tasks.indexOf task

    await @meetings.updateAsync
      _id: meeting_id
    ,
      $set: update

  saveSubTaskSubjectAsync: (meeting_id, task_id, added_task_id, added_task_subject, user_id) ->

    @_requireString meeting_id, "meeting_id should be a string"
    check task_id, String
    check added_task_id, String
    meeting = await @_requireMeetingMemberAsync meeting_id, false, user_id
    meeting_task = _.findWhere meeting.tasks, { task_id: task_id }

    if not meeting_task?
      throw @_error "invalid-request", "Task is not part of meeting."

    query =
      meeting_id: meeting_id
      task_id: task_id
      "added_tasks.task_id": added_task_id
    op =
      $set:
        'added_tasks.$.title': added_task_subject

    await @meetings_tasks.updateAsync query, op

    return



  addSubTaskToTaskAsync: (meeting_id, task_id, task_fields, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"
    @_requireObject task_fields, "fields should be an object"

    # XXX validate task_fields against a schema

    meeting = await @_requireMeetingMemberAsync meeting_id, false, user_id
    meeting_task = _.findWhere meeting.tasks, { task_id: task_id }

    if not meeting_task?
      throw @_error "invalid-request", "Task is not part of meeting."

    new_task_id = APP.projects._grid_data_com.addChild(
      "/" + task_id + "/"
    ,
      project_id: meeting.project_id
      title: task_fields.title
      created_from_meeting_id: meeting_id
    ,
      user_id
    )

    new_task = await @tasks.findOneAsync new_task_id

    await @meetings_tasks.updateAsync
      _id: meeting_task.id
    ,
      $push:
        added_tasks:
          task_id: new_task_id
          title: task_fields.title
          seqId: new_task.seqId
          added_by: user_id
          added_at: new Date()

    return new_task_id

  setNoteForTaskAsync: (meeting_id, task_id, note_fields, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"
    @_requireString task_id, "task_id should be a string"
    @_requireObject note_fields, "fields should be an object"

    # TODO: validate note_fields against a schema

    meeting = await @_requireMeetingMemberAsync meeting_id, false, user_id
    meeting_task = _.findWhere meeting.tasks, { task_id: task_id }

    if not meeting_task?
      throw @_error "invalid-request", "Task is not part of meeting."

    meeting_task_id = meeting_task.id

    # Update the note text
    await @meetings_tasks.updateAsync
      _id: meeting_task_id
    ,
      $set:
        "note": note_fields.note
        "note_lock": note_fields.note_lock

  addUserNoteToTaskAsync: (...args) ->
    # There's actually no difference at the moment between these two methods
    # there might be in the future.
    await @setUserNoteForTaskAsync.apply(this, args)

  setUserNoteForTaskAsync: (meeting_id, task_id, note_fields, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"
    @_requireString task_id, "task_id should be a string"
    @_requireObject note_fields, "fields should be an object"

    # TODO: validate note_fields against a schema

    meeting = await @_requireMeetingMemberAsync meeting_id, false, user_id
    meeting_task = _.findWhere meeting.tasks, { task_id: task_id }

    if not meeting_task?
      throw @_error "invalid-request", "Task is not part of meeting."

    meeting_task_id = meeting_task.id

    query =
      _id: meeting_task_id
      user_notes:
        $not:
          $elemMatch:
            user_id: user_id
    
    update =
      $push:
        user_notes:
          user_id: user_id
          date_added: new Date()

    # Ensure that the note exists
    await JustdoHelpers.findOneAndUpdateAsync @meetings_tasks, query, update

    # Update the note text
    await @meetings_tasks.updateAsync
      _id: meeting_task_id
      user_notes:
        $elemMatch:
          user_id: user_id
    ,
      $set:
        "user_notes.$.note": note_fields.note
        "user_notes.$.date_updated": new Date()

  addPrivateNoteToTaskAsync: (...args) ->
    # There's actually no difference at the moment between these two methods
    # there might be in the future.
    await @setPrivateNoteForTaskAsync.apply(this, args)

  setPrivateNoteForTaskAsync: (meeting_id, task_id, note_fields, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"
    @_requireString task_id, "task_id should be a string"
    @_requireObject note_fields, "fields should be an object"

    # TODO: validate note_fields against a schema

    meeting = await @_requireMeetingMemberAsync meeting_id, false, user_id
    meeting_task = _.findWhere meeting.tasks, { task_id: task_id }

    if not meeting_task?
      throw @_error "invalid-request", "Task is not part of meeting."

    meeting_task_id = meeting_task.id

    update =
      updatedAt: new Date()

    if note_fields.note?
      update.note = note_fields.note

    await @meetings_private_notes.upsertAsync
      meeting_id: meeting_id
      task_id: task_id
      user_id: user_id
    ,
      $set: update

  updateMeetingLockAsync: (meeting_id, locked, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"
    @_requireBoolean locked, "locked should be true or false"
    await @_requireMeetingOrganizerAsync meeting_id, user_id

    await @meetings.updateAsync { _id: meeting_id }, { $set: { locked: locked } }

  updateMeetingPrivacyAsync: (meeting_id, isPrivate, user_id) ->
    @_requireString meeting_id, "meeting_id should be a string"
    @_requireBoolean isPrivate, "private should be true or false"
    await @_requireMeetingOrganizerAsync meeting_id, user_id

    await @meetings.updateAsync { _id: meeting_id }, { $set: { private: isPrivate } }

  _requireString: (value, message) ->
    if not _.isString value
      throw @_error "invalid-request", message

  _requireObject: (obj, message) ->
    if not _.isObject obj
      throw @_error "invalid-request", message

  _requireBoolean: (obj, message) ->
    if not _.isBoolean obj
      throw @_error "invalid-request", message

  _requireProjectMemberAsync: (project_id, user_id) ->
    project = await @projects.findOneAsync { _id: project_id }

    if not project?
      throw @_error "not-project-member"
    if not _.findWhere(project.members, { user_id: user_id })?
      throw @_error "not-project-member"

    return project

  getMeetingIfAccessibleAsync: (meeting_id, user_id) ->
    self = @
    meeting = await self.meetings.findOneAsync meeting_id,
      fields:
        users: 1
        tasks: 1
    
    if not meeting?
      return null

    if user_id in meeting.users
      return meeting
    
    filtered_tasks = await self.filterAccessableMeetingTasksAsync meeting.tasks, user_id, "remove"
    if filtered_tasks?.length > 0
      return meeting
    
    return null

  _isTaskMemberAsync: (task_id, user_id) ->
    task = await @tasks.findOneAsync
      _id: task_id
      users: user_id
    ,
      fields:
        _id: 1
        
    return task?

  _requireTaskMemberAsync: (task_id, fields, user_id) ->
    check fields, Object
    
    fields = _.extend {}, fields,
      _id: 1
      users: 1
      
    task = await @tasks.findOneAsync { _id: task_id }, {fields: fields}

    if not task?
      throw @_error "not-task-member"
    if not _.contains task.users, user_id
      throw @_error "not-task-member"

    return task

  _requireMeetingMemberAsync: (meeting_id, needs_unlock, user_id) ->
    meeting = await @meetings.findOneAsync { _id: meeting_id }

    if not meeting?
      throw @_error "not-meeting-member"

    if meeting.organizer_id != user_id

      if not _.contains meeting.users, user_id
        throw @_error "not-meeting-member"

      if needs_unlock && meeting.locked
        throw @_error "not-meeting-organizer"

      if meeting.status == "draft"
        throw @_error "not-meeting-organizer"

    return meeting

  _requireProjectMemberOrPublicAsync: (meeting_id, user_id) ->
    meeting = await @meetings.findOneAsync { _id: meeting_id }

    if not meeting?
      throw @_error "not-meeting-member"

    if meeting.organizer_id != user_id

      if (not _.contains meeting.users, user_id) and (meeting.private == true)
        throw @_error "not-meeting-member"

      if meeting.status == "draft"
        throw @_error "not-meeting-organizer"

    return meeting

  _requireMeetingOrganizerAsync: (meeting_id, user_id) ->
    meeting = await @meetings.findOneAsync { _id: meeting_id }

    if not meeting?
      throw @_error "not-meeting-member"

    if meeting.organizer_id != user_id
      throw @_error "not-meeting-organizer"

    return meeting

  _requireTaskIsUnique: (tasks_list, task_id) ->

    if (_.findWhere tasks_list, { task_id: task_id })?
      throw @_error "duplicate-task"

  _requireTaskFromSearchAsync: (search, project_id, user_id) ->

    project = await @projects.findOneAsync { _id: project_id }

    query =
      users: user_id
      project_id: project_id

    if search.task_id?
      query._id = search.task_id

    else if search.seqId?
      query.seqId = Number(search.seqId)

    task = await @tasks.findOneAsync query

    if not task?
      throw @_error "not-task-member", "Could not find the specified task."

    return task

  # This method validates an object against a schema using only keys which
  # exist in the object. This will still throw for required keys, (e.g. if the
  # user set's a required key to null or undefined or an empty string) but
  # allows us to validate partial modifiers.
  # Also, this will throw on un-allowed keys, which is important.

  _requireValidatedPartialObject: (obj, schema) ->
    keys = []
    for key of obj
      keys.push(key)

    # Thin the schema to only include the keys which exist in the object,
    # that way we can validate { $set } operations.
    schema = schema.pick keys
    obj = schema.clean obj,
      filter: false # Don't remove properties which don't belong, instead throw an error.
      autoConvert: true
      removeEmptyStrings: false # Don't remove empty strings, that might be what the user wanted
      trimStrings: true
      getAutoValues: false # Don't use autovalue, because this is supposed to be a partial update

    schema.validate obj

  deleteMeetingAsync: (meeting_id, user_id) ->
    self = @

    check meeting_id, String
    check user_id, String

    meeting = await @meetings.findOneAsync meeting_id,
      fields:
        organizer_id: 1
        project_id: 1
    
    project = await APP.collections.Projects.findOneAsync 
      _id: meeting.project_id
    ,
      fields:
        _id: 1
        conf: 1
        members: 1
    
    is_admin = false
    for member in project.members
      if member.user_id == user_id and member.is_admin
        is_admin = true
        break

    if project.conf.block_meetings_deletion == true or
        (meeting.organizer_id != user_id and not is_admin)
      throw @_error "permission-denied"

    await @meetings.removeAsync meeting_id

    await @meetings_tasks.find(
      meeting_id: meeting_id
    ,
      fields:
        task_id: 1
    ).forEachAsync (meeting_task) ->
      await self.recalTaskMeetingsCacheAsync(meeting_task.task_id)

    return

  updateAddedTaskNoteAsync: (meeting_task_id, added_task_id, changes, user_id) ->
    check meeting_task_id, String
    check added_task_id, String
    check changes, Object
    check user_id, String

    set_modifier = {}
    for field, val of changes
      set_modifier["added_tasks.$.#{field}"] = val

    await @meetings_tasks.updateAsync
      _id: meeting_task_id
      "added_tasks.task_id": added_task_id
    ,
      $set: set_modifier

    return

  filterAccessableMeetingTasksAsync: (tasks, user_id, action="remove") ->
    task_ids = _.map tasks, (task) -> task.task_id
    accessable_task_ids = []
    
    await APP.collections.Tasks.find
      _id:
        $in: task_ids
      users: user_id
    ,
      fields:
        _id: 1
    .forEachAsync (task) ->
      accessable_task_ids.push task._id
      return
    
    filtered_tasks = null

    if action == "remove"
      filtered_tasks = _.filter tasks, (task) -> task.task_id in accessable_task_ids
    else if action == "supress_fields"
      filtered_tasks = _.map tasks, (task) -> 
        if not (task.task_id in accessable_task_ids)
          delete task.title
        return task
    
    return filtered_tasks

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
