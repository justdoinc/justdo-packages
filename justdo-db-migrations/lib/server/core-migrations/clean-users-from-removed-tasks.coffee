APP.executeAfterAppLibCode ->
  migration_name = "clean-users-from-removed-tasks"
  APP.justdo_db_migrations.registerMigrationScript migration_name, JustdoDbMigrations.perpetualMaintainer
    delay_between_batches: 15000
    batch_size: 1000
    collection: APP.collections.Tasks
    updated_at_field: "_raw_updated_date"
    queryGenerator: ->
      # IMPORTANT!!! this is a JustdoDbMigrations.perpetualMaintainer and not a JustdoDbMigrations.commonBatchedMigration .
      # The queryGenerator of a perpetualMaintainer receives only the query and no query options.
      # Here you can define custom fields to fetch under custom_fields_to_fetch.
      return {_raw_removed_date: {$ne: null}, users: {$ne: []}}
    exec_interval: 5 * 1000 # 5 seconds
    checkpoint_record_name: "#{migration_name}-checkpoint"
    custom_fields_to_fetch: {
      users: 1
    }
    batchProcessorForEach: (doc) ->
      update_query = {$set: {users: []}, $addToSet: { _raw_removed_users: {$each: doc.users}}}
      APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(update_query)

      for user_id in doc.users
        # $currentDate will be added by _addRawFieldsUpdatesToUpdateModifier
        update_query["$currentDate"]["_raw_removed_users_dates.#{user_id}"] = true

      APP.collections.Tasks.direct.update({_id: doc._id}, update_query, {bypassCollection2: true})

      return

  return