_.extend JustdoDbMigrations.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "getUsersRecentBatchedOps", -> # Note the use of -> not =>, we need @userId
      return self.getUsersRecentBatchedOpsCursor(@userId)

    return