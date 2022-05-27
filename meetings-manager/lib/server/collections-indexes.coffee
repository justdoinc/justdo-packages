_.extend MeetingsManager.prototype,
  _ensureIndexesExists: -> 
    @meetings_tasks._ensureIndex {task_id: 1}
    @meetings_tasks._ensureIndex {meeting_id: 1}
    return