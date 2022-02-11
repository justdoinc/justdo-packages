_.extend JustdoDbMigrations.prototype,
  _setupJobs: () ->
    self = @

    for migration_script_id, migration_script_options of @migration_scripts
      @registerMigrationScript migration_script_id, migration_script_options
      
    APP.justdo_jobs_processor.registerCronJob "db-migrations", =>
      if _.isEmpty self.registered_migration_scripts
        console.log "No registered migration script found."
        return

      for migration_script in self.registered_migration_scripts
        console.log "Executing migration script #{migration_script.id}."
        migration_script.jobInit()
        console.log "#{migration_script.id} finished executing."
        return
    , =>
      for migration_script in self.registered_migration_scripts
        console.log "Stopping migration script #{migration_script.id}."
        migration_script.jobStop()
        console.log "#{migration_script.id} stopped."
        return
    return
