_.extend JustdoKanban.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "kanbans", (task_id) ->
      return self.kanbans_collection.find(task_id)

    return