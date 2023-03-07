_.extend JustdoFiles.prototype,
  _setupPublications: -> 
    @_publishTaskFiles()

    return

  _publishTaskFiles: ->
    self = @

    Meteor.publish "jdfTaskFiles", (task_id) ->
      return self.tasksFilesPublicationHandler(@, task_id, @userId)

    return
