APP.executeAfterAppLibCode ->
  migration_name = "remove-residual-temp-import-id"

  APP.justdo_db_migrations.registerMigrationScript migration_name, JustdoDbMigrations.perpetualMaintainer
    delay_between_batches: 3000
    batch_size: 100
    collection: APP.collections.Tasks
    updated_at_field: "_raw_updated_date"
    # This is a 2nd layer protection for orphaned temp_import_ids (e.g., if import crashed or user closed browser).
    # The primary cleanup happens via clearupTempImportId() when import completes successfully.
    # The 1-hour delay avoids interrupting long-running imports that are still in progress.
    delayed_updated_at_field: 1000 * 60 * 60
    queryGenerator: ->
      # IMPORTANT!!! this is a JustdoDbMigrations.perpetualMaintainer and not a JustdoDbMigrations.commonBatchedMigration .
      # The queryGenerator of a perpetualMaintainer receives only the query and no query options.
      # Here you can define custom fields to fetch under custom_fields_to_fetch.
      return {"jci:temp_import_id" : {$ne: null}}
    exec_interval: 5 * 1000
    custom_fields_to_fetch: {}
    batchProcessorForEach: (doc) ->
      update_query = {$unset: {"jci:temp_import_id": 1}}
      APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(update_query)

      APP.collections.Tasks.direct.update({_id: doc._id}, update_query, {bypassCollection2: true})

      return

  return