common_batched_migration_options =
  delay_between_batches: 1000

  collection: APP.collections.Projects

  pending_migration_set_query:
    timezone:
      $exists: false
    members:
      $elemMatch:
        is_admin: true

  pending_migration_set_query_options:
    members:
      $elemMatch:
        is_admin: true
    limit: 100

  custom_options:
    user_id_to_timezone: {} # Caches queried admin timezones
    fallback_timezone: moment.tz.guess()

  batchProcessor: (cursor, collection, options) ->
    num_processed = 0
    timezone_to_project = {}

    cursor.forEach (project) ->
      admin_id = project.members[0].user_id
      if not (timezone = options.user_id_to_timezone[admin_id])?
        admin = Meteor.users.findOne
          _id: admin_id
          "profile.timezone":
            $exists: true
        ,
          fields:
            "profile.timezone": 1

        timezone = admin?.profile?.timezone or options.fallback_timezone

        options.user_id_to_timezone[admin_id] = timezone

      if timezone_to_project[timezone]?
        timezone_to_project[timezone].push project._id
      else
        timezone_to_project[timezone] = [project._id]

    for timezone, project_ids of timezone_to_project
      num_processed += collection.update
        _id:
          $in: project_ids
      ,
        $set:
          timezone: timezone
      ,
        multi: true

    return num_processed

APP.justdo_db_migrations.registerMigrationScript "justdo-timezone", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)
