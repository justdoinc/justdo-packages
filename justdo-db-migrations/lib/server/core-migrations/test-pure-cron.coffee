APP.executeAfterAppLibCode ->
  test_cron_job_processed = false
  # When this flag is false, `queryGenerator` will return a document so that `batchProcessor` will be called;
  # After `batchProcessor` is called, the flag is set to true so that `queryGenerator` will return no document,
  # so that `commonBatchedMigration` would think there are no more documents to process, allowing the script to enter monitor mode.

  test_cron_job = JustdoDbMigrations.registerCronjob
    id: "test-cron-job"
    cron_expression: "*/10 * * * * *"

    common_batch_migration_options:
      collection: APP.collections.Tasks
      delay_between_batches: 1000
      batch_size: 1
      starting_condition_interval_between_checks: 60 * 1000

      queryGenerator: ->
        query = {}
        if test_cron_job_processed
          query = {_id: null}
          test_cron_job_processed = false

        return {query, query_options: {limit: 1}}
      static_query: false

      batchProcessor: (cursor) ->
        date = new Date()
        @logProgress "Setting `test_cron_job` to #{date}"

        APP.justdo_system_records.setRecord "test_cron_job",
          value: date
        ,
          jd_analytics_skip_logging: true

        test_cron_job_processed = true

        return 1

  # Register the migration with the db-migrations system
  APP.justdo_db_migrations.registerMigrationScript "test-cron-job", test_cron_job
  return