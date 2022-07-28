migration_name = "remove-residual-temp-import-id"

APP.justdo_db_migrations.registerMigrationScript migration_name, JustdoDbMigrations.perpetualMaintainer
  delay_between_batches: 15000
  batch_size: 1000
  collection: APP.collections.Tasks
  updated_at_field: "_raw_updated_date"
  delayed_updated_at_field: 60 * 1000
  queryGenerator: ->
    return {"jci:temp_import_id" : {$ne: null}}
  exec_interval: 2 * 60 * 1000 # 2 mins, DON'T SET THIS TO BELOW delayed_updated_at_field
  checkpoint_record_name: "#{migration_name}-checkpoint"
  custom_fields_to_fetch: {}
  batchProcessorForEach: (doc) ->
    update_query = {$unset: {"jci:temp_import_id": 1}}
    APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(update_query)

    APP.collections.Tasks.direct.update({_id: doc._id}, update_query, {bypassCollection2: true})

    return

