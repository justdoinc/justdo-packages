_.extend MeetingsManager.prototype,
  _immediateInit: ->
    self = @

    # meetings cache migration
    meetings_cache_field_batched_migration_options =
      delay_between_batches: 1000
      batch_size: 2

      collection: self.meetings_tasks

      queryGenerator: ->
        query =
          is_meetings_cache_migration_script_executed:
            $ne: true

        query_options = 
          fields:
            _id: 1
            task_id: 1
            
        return {query, query_options}

      static_query: true

      mark_as_completed_upon_batches_exhaustion: true

      custom_options: {}

      initProcedures: ->
        return

      batchProcessor: (cursor) ->
        num_processed = 0
        meeting_task_ids = []
        task_ids = new Set()

        cursor.forEach (meeting_task) ->
          task_ids.add(meeting_task.task_id)
          meeting_task_ids.push meeting_task._id
          num_processed += 1
          return
        
        task_ids.forEach (task_id) ->
          self.recalTaskMeetingsCache(task_id)

          return
        
        self.meetings_tasks.update
          _id:
            $in: meeting_task_ids
        ,
          $set:
            is_meetings_cache_migration_script_executed: true
        ,
          multi: true
        
        return num_processed

      terminationProcedures: ->
        return

    APP.justdo_db_migrations.registerMigrationScript "meetings-cache-field", JustdoDbMigrations.commonBatchedMigration(meetings_cache_field_batched_migration_options)

    return

  _deferredInit: ->
    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return