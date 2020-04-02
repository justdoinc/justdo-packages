_.extend JustdoKanban.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      kanban_createKanban: (task_id) ->
        self.createKanban task_id, @userId
        return

      kanban_updateKanban: (task_id, key, val) ->
        self.updateKanban task_id, key, val, @userId
        return

    return
