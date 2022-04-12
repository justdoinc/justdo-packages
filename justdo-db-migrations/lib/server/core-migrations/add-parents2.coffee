common_batched_migration_options =
  delay_between_batches: 1000 * 10
  batch_size: 10000

  collection: APP.collections.Tasks

  queryGenerator: ->
    query =
      parents2: null
      corrupted_parents: null
      _raw_removed_date: null
      parents: {$ne: null}

    query_options =
      fields:
        parents: 1
    return {query, query_options}
  static_query: true

  mark_as_completed_upon_batches_exhaustion: true

  batchProcessor: (tasks_cursor) ->
    self = @
    num_processed = 0
    tasks_cursor.forEach (task) =>
      parents2 = []
      for parent_id, order_obj of task.parents
        if order_obj is null
          self.logWarning "Task #{task._id} had a parent with corrupted parents def object - renaming the parents field to 'corrupted_parents'"

          num_processed += 1
          @collection.rawCollection().update {_id: task._id}, {$set: {corrupted_parents: task.parents}, $unset: {parents: 1}}

          return

        parents2.push {parent: "#{parent_id}", order: order_obj.order}

      num_processed += @collection.direct.update({_id: task._id}, {$set: {parents2: parents2}}, {bypassCollection2: true})

    return num_processed

APP.justdo_db_migrations.registerMigrationScript "add-parents2", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)
