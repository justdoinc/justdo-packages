_.extend JustdoKanban.prototype,
  createKanban: (task_id, callback) ->
    return Meteor.call "kanban_createKanban", task_id, callback

  updateKanban: (task_id, key, val, callback) ->
    return Meteor.call "kanban_updateKanban", task_id, key, val, callback
