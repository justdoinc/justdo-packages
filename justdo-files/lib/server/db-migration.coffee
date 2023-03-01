 _.extend JustdoFiles.prototype,
  _setupDbMigrations: ->
    justdo_files_add_project_id_batched_migration_options =
      delay_between_batches: 1000
      batch_size: 100

      collection: APP.justdo_files.tasks_files.collection

      queryGenerator: ->
        query =
          "meta.project_id": null
          "meta.task_id":
            $ne: null

        query_options =
          fields:
            "meta.task_id": 1

        return {query, query_options}

      static_query: false

      mark_as_completed_upon_batches_exhaustion: true

      custom_options: {}

      initProcedures: ->
        return

      batchProcessor: (cursor) ->
        num_processed = 0
        processed_project_ids = new Set()

        cursor.forEach (file_doc) =>
          task_id = file_doc.meta.task_id

          if not (project_id = APP.collections.Tasks.findOne(task_id, {fields: {project_id: 1}})?.project_id)?
            # If we can't find project_id in Tasks collection, the task is probably remvoed.
            # Attempt to get project_id in removed tasks collection
            project_id = APP.collections.RemovedProjectsTasksArchiveCollection.findOne(task_id, {fields: {project_id: 1}})?.project_id

          if project_id? and not processed_project_ids.has project_id
            processed_project_ids.add project_id

            query =
              "meta.task_id": task_id
            ops =
              $set:
                "meta.project_id": project_id
            res = APP.justdo_files.tasks_files.collection.update(query, ops, {multi: true})
            num_processed += res

          return

        return num_processed

      terminationProcedures: ->
        return

    APP.justdo_db_migrations.registerMigrationScript "justdo-files-add-project-id", JustdoDbMigrations.commonBatchedMigration(justdo_files_add_project_id_batched_migration_options)

    return
