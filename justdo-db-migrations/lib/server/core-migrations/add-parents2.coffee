common_batched_migration_options =
  delay_between_batches: 1000

  collection: APP.collections.Tasks

  pending_migration_set_query:
    parents2:
      $exists: false

  pending_migration_set_query_options:
    fields:
      parents: 1
    limit: 300

  batchProcessor: (tasks_cursor, tasks_collection) ->
    num_processed = 0
    tasks_cursor.forEach (task) ->
      {_id, parents} = task
      parents2 = []
      for parent_id, order_obj of parents
        parents2.push {parent: "#{parent_id}", order: order_obj.order}

      num_processed += tasks_collection.update _id, {$set: {parents2: parents2}}

    return num_processed

APP.justdo_db_migrations.registerMigrationScript "add-parents2", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)
