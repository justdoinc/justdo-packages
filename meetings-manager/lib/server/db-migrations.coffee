_.extend MeetingsManager.prototype,
  setupDbMigrations: ->
    self = @

    # meetings cache migration
    meetings_cache_field_batched_migration_options =
      delay_between_batches: 1000
      batch_size: 100

      collection: self.meetings_tasks

      queryGenerator: ->
        query =
          _id:
            $gt: APP.justdo_system_records.getRecord("task-meetings-cache-field-migration-last-id")?.value or ""

        query_options = 
          fields:
            _id: 1
            task_id: 1
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
        last_meeting_task_id = null
        task_ids = new Set()

        cursor.forEach (meeting_task) ->
          task_ids.add(meeting_task.task_id)
          last_meeting_task_id = meeting_task._id
          num_processed += 1
          return
        
        task_ids.forEach (task_id) ->
          self.recalTaskMeetingsCache(task_id)

          return
        
        APP.justdo_system_records.setRecord("task-meetings-cache-field-migration-last-id", 
          value: last_meeting_task_id
        )

        return num_processed

      terminationProcedures: ->
        return

    APP.justdo_db_migrations.registerMigrationScript "meetings-cache-field", JustdoDbMigrations.commonBatchedMigration(meetings_cache_field_batched_migration_options)

    return