_.extend JustdoDbMigrations.prototype,
  _setupJobs: ->
    self = @

    APP.justdo_jobs_processor.registerCronJob "db-migrations", =>
      @runAllMigrationScripts()

      return
    , =>
      @haltAllRunningMigrationScripts()

      return
    return
