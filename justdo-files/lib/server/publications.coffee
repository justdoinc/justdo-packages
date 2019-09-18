_.extend JustdoFiles.prototype,
  _setupPublications: -> 
    @_publishTaskFiles()
    return

  _publishTaskFiles: ->
    self = @
    Meteor.publish null, ->
      return self.tasks_files.find().cursor 
    