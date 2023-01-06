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
          
          @collection.rawCollection().update({_id: task._id}, {
            $set:
              [TasksFileManager.files_count_field_id]: task.files.length
          })

          return

        return num_processed

      terminationProcedures: ->
        return

    APP.justdo_db_migrations.registerMigrationScript "tasks-file-manager-files-count", JustdoDbMigrations.commonBatchedMigration(tasks_file_manager_files_count_batched_migration_options)

    restore_task_updatedAt_migration_options =
      delay_between_batches: 1000
      batch_size: 100

      collection: APP.collections.Tasks

      queryGenerator: ->
        query =
          _id:
            $nin: APP.justdo_system_records.getRecord("restored-updatedAt-tasks")?.processed_task_ids or []
          [TasksFileManager.files_count_field_id]:
            $ne: null

        query_options =
          fields:
            _id: 1

        return {query, query_options}

      static_query: false

      mark_as_completed_upon_batches_exhaustion: true

      custom_options: {}

      initProcedures: ->
        return

      batchProcessor: (cursor) ->
        num_processed = 0

        processed_task_ids = cursor.map (task) =>
          query =
            task_id: task._id
          query_options =
            fields:
              when: 1
            sort:
              when: -1
          most_recent_changelog_time = APP.collections.TasksChangelog.findOne(query, query_options).when

          @collection.rawCollection().update({_id: task._id}, {
            $set:
              updatedAt: most_recent_changelog_time
          })

          num_processed += 1

          return task._id

        APP.collections.SystemRecords.upsert "restored-updatedAt-tasks",
          $addToSet:
            processed_task_ids:
              $each: processed_task_ids

        return num_processed

      terminationProcedures: ->
        return

    APP.justdo_db_migrations.registerMigrationScript "restore-task-updated-at-field", JustdoDbMigrations.commonBatchedMigration(restore_task_updatedAt_migration_options)

    return
