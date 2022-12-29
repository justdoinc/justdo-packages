 _.extend TasksFileManager.prototype,
  _setupDbMigrations: -> 
    tasks_file_manager_files_count_batched_migration_options =
      delay_between_batches: 1000
      batch_size: 100

      collection: APP.collections.Tasks

      queryGenerator: ->
        query =
          "files":
            $ne: null
          [TasksFileManager.files_count_field_id]:
            $eq: null

        query_options = 
          fields:
            "files": 1
          
        return {query, query_options}

      static_query: true

      mark_as_completed_upon_batches_exhaustion: true

      custom_options: {}

      initProcedures: ->
        return

      batchProcessor: (cursor) ->
        num_processed = 0
        
        cursor.forEach (task) =>
          num_processed += 1
          
          if task.files.length > 0
            @collection.update(task._id, {
              $set:
                [TasksFileManager.files_count_field_id]: task.files.length
            })

        return num_processed

      terminationProcedures: ->
        return

    APP.justdo_db_migrations.registerMigrationScript "tasks-file-manager-files-count", JustdoDbMigrations.commonBatchedMigration(tasks_file_manager_files_count_batched_migration_options)

    return