_.extend CustomJustdoTasksLocks.prototype,
  toggleTaskLockedState: (task_id, cb) ->
    return Meteor.call "jdtlToggleTaskLockedState", task_id, cb