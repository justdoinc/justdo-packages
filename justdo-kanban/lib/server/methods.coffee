_.extend JustdoKanban.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      kanban_addSubTask: (parent_task_id, options) ->
        user_id = @userId
        self.addSubTask parent_task_id, options, user_id

      kanban_removeSubTask: (parent_task_id, subtask_id, callback) ->
        user_id = @userId
        self.removeSubTask parent_task_id, subtask_id, user_id, callback

      kanban_createKanban: (task_id) ->
        user_id = @userId
        self.createKanban task_id, user_id

      kanban_setMemberFilter: (task_id, active_member_id) ->
        user_id = @userId
        self.setMemberFilter task_id, active_member_id, user_id

      kanban_setSortBy: (task_id, sortBy, reverse) ->
        user_id = @userId
        self.setSortBy task_id, sortBy, reverse, user_id

      kanban_addState: (task_id, state_object) ->
        user_id = @userId
        self.addState task_id, state_object, user_id

      kanban_updateStateOption: (task_id, state_id, option_id, option_label, new_value) ->
        user_id = @userId
        self.updateStateOption task_id, state_id, option_id, option_label, new_value, user_id

    return
