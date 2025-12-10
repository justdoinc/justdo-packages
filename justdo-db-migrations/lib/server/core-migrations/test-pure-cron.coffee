APP.executeAfterAppLibCode ->
  test_cron_job = JustdoDbMigrations.registerCronjob
    id: "test-cron-job"
    cron_expression: "*/27 * * * * *"
    job: ->
      date = new Date()
      @logProgress "Setting `test_cron_job` to #{date}"

      APP.justdo_system_records.setRecord "test_cron_job",
        value: date
      ,
        jd_analytics_skip_logging: true
      
      @setCheckpoint()
        
      return

  # Register the migration with the db-migrations system
  APP.justdo_db_migrations.registerMigrationScript "test-cron-job", test_cron_job
  return