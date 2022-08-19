APP.executeAfterAppLibCode -> # Could have been avoided if we could add the following line to package.js, but it creates circular dep: api.use("stem-capital:projects@0.1.0", both); // Needed for add-justdo-timezone.coffee to have APP.collections.Projects
  common_batched_migration_options =
    delay_between_batches: 1000
    batch_size: 100

    collection: APP.collections.Projects

    queryGenerator: ->
      query =
        timezone:
          $exists: false
        members:
          $elemMatch:
            is_admin: true

      query_options =
        fields:
          members:
            $elemMatch:
              is_admin: true
      return {query, query_options}
    static_query: true

    mark_as_completed_upon_batches_exhaustion: true

    custom_options:
      fallback_timezone: moment.tz.guess()

    initProcedures: ->
      @shared.user_id_to_timezone = {}

      return

    batchProcessor: (cursor) ->
      num_processed = 0
      timezone_to_project = {}

      cursor.forEach (project) =>
        admin_id = project.members[0].user_id
        if not (timezone = @shared.user_id_to_timezone[admin_id])?
          admin = Meteor.users.findOne
            _id: admin_id
            "profile.timezone":
              $exists: true
          ,
            fields:
              "profile.timezone": 1

          timezone = admin?.profile?.timezone or @options.fallback_timezone

          @shared.user_id_to_timezone[admin_id] = timezone

        if timezone_to_project[timezone]?
          timezone_to_project[timezone].push project._id
        else
          timezone_to_project[timezone] = [project._id]

      for timezone, project_ids of timezone_to_project
        num_processed += @collection.update
          _id:
            $in: project_ids
        ,
          $set:
            timezone: timezone
        ,
          multi: true

      return num_processed

    terminationProcedures: ->
      @shared.user_id_to_timezone = null # Ensure GC cleanup

      return

  APP.justdo_db_migrations.registerMigrationScript "justdo-timezone", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)

  return