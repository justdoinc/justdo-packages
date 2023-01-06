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
          [TasksFileManager.files_count_field_id]:
            $ne: null

        # To avoid re-cheking the same batch of documents again and again, the cursor is sorted by the task id.
        # We store the last checked task id in system-records and use it as the starting point of the next batch of documents
        if (previous_checkpoint = APP.justdo_system_records.getRecord("restored-updatedAt-tasks")?.previous_checkpoint)?
          query._id =
            $gt: previous_checkpoint

        query_options =
          fields:
            _id: 1
          sort:
            _id: 1

        return {query, query_options}

      static_query: false

      mark_as_completed_upon_batches_exhaustion: true

      custom_options: {}

      initProcedures: ->
        return

      batchProcessor: (cursor) ->
        num_processed = 0
        checkpoint = null

        cursor.forEach (task) =>
          query =
            task_id: task._id
          query_options =
            fields:
              when: 1
            sort:
              when: -1
          # Normally when a new task is created, a changelog doc is also created alongside.
          # If we face a task that doesn't have any changelogs, it's likely created with taskGenerator.
          # In this case we simply ignore it.
          if not (most_recent_changelog_time = APP.collections.TasksChangelog.findOne(query, query_options)?.when)?
            console.log "#{task._id} has no changelog. Ignored."
            return

          @collection.rawCollection().update({_id: task._id}, {
            $set:
              updatedAt: most_recent_changelog_time
          })

          num_processed += 1
          checkpoint = task._id

          return

        APP.collections.SystemRecords.upsert "restored-updatedAt-tasks",
          $set:
            previous_checkpoint: checkpoint

        return num_processed

      terminationProcedures: ->
        return

    APP.justdo_db_migrations.registerMigrationScript "restore-task-updated-at-field", JustdoDbMigrations.commonBatchedMigration(restore_task_updatedAt_migration_options)

    return
