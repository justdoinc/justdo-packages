_.extend JustdoKanban.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "kanbans", (task_id) ->
      return self.kanbans.find(task_id)
