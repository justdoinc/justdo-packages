_.extend JustdoKanban.prototype,
  createKanban: (task_id, callback) ->
    return Meteor.call "kanban_createKanban", task_id, callback

  setMemberFilter: (task_id, active_member_id, callback) ->
    return Meteor.call "kanban_setMemberFilter", task_id, active_member_id, callback

  setSortBy: (task_id, sortBy, reverse, callback) ->
    return Meteor.call "kanban_setSortBy", task_id, sortBy, reverse, callback

  addState: (task_id, state_object, callback) ->
    return Meteor.call "kanban_addState", task_id, state_object, callback

  updateStateOption: (task_id, state_id, option_id, option_label, new_value, callback) ->
    return Meteor.call "kanban_updateStateOption", task_id, state_id, option_id, option_label, new_value, callback
