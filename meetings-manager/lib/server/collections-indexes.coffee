_.extend MeetingsManager.prototype,
  _ensureIndexesExists: -> 
    await @meetings_tasks.createIndexAsync {task_id: 1}
    await @meetings_tasks.createIndexAsync {meeting_id: 1}
    return