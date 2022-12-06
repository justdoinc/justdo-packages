_.extend JustdoDbMigrations.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      terminateBatchedCollectionUpdatesJob: (job_id) ->
        check job_id, String

        self.terminateBatchedCollectionUpdatesJob(job_id, @userId)

    return