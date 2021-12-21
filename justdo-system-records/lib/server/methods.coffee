_.extend JustdoSystemRecords.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "ky-10894": ->
        self.setRecord "skip-justdo-licensing"
        return

    return