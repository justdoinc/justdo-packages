APP.executeAfterAppLibCode ->
  migration_name = "remove-residual-temp-import-id"

  APP.justdo_db_migrations.registerMigrationScript migration_name, JustdoDbMigrations.perpetualMaintainer
    delay_between_batches: 3000
    batch_size: 100
    collection: APP.collections.Tasks
    updated_at_field: "_raw_updated_date"
    delayed_updated_at_field: 1000 * 60 * 2 # Delay to avoid interrupting on-going active clipboard imports.
    queryGenerator: ->
      # IMPORTANT!!! this is a JustdoDbMigrations.perpetualMaintainer and not a JustdoDbMigrations.commonBatchedMigration .
      # The queryGenerator of a perpetualMaintainer receives only the query and no query options.
      # Here you can define custom fields to fetch under custom_fields_to_fetch.
      return {"jci:temp_import_id" : {$ne: null}}
    exec_interval: 5 * 1000
    checkpoint_record_name: "#{migration_name}-checkpoint"
    custom_fields_to_fetch: {}
    batchProcessorForEach: (doc) ->
      update_query = {$unset: {"jci:temp_import_id": 1}}
      APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(update_query)

      APP.collections.Tasks.direct.update({_id: doc._id}, update_query, {bypassCollection2: true})

      return

  return