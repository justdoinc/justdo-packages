_.extend JustdoKanban.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      kanban_createKanban: (task_id) ->
        self.createKanban task_id, @userId

        return

      kanban_setMemberFilter: (task_id, active_member_id) ->
        self.setMemberFilter task_id, active_member_id, @userId

        return

      kanban_setSortBy: (task_id, sortBy, reverse) ->
        self.setSortBy task_id, sortBy, reverse, @userId

        return

      kanban_addState: (task_id, state_object) ->
        self.addState task_id, state_object, @userId

        return

      kanban_updateStateOption: (task_id, state_id, option_id, option_label, new_value) ->
        self.updateStateOption task_id, state_id, option_id, option_label, new_value, @userId

        return

    return
