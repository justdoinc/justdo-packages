_.extend JustdoChecklist.prototype,
  toggleCheckItemSwitch: (task_id, cb) ->
    return Meteor.call "jdchToggleCheckItemSwitch", task_id, cb
