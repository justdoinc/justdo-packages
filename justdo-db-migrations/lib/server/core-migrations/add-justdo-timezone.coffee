batch_size = 300
user_id_to_timezone = {} # Caches queried admin timezones

APP.justdo_db_migrations.registerMigrationScript "justdo-timezone",
  runScript: ->
    # The two var below are solely for logging progress
    initial_affected_docs_count = 0
    num_processed = 0

    query =
      timezone:
        $exists: false

    options =
      fields:
        members:
          $elemMatch:
            is_admin: true
      limit: batch_size

    projects_without_timezone_cursor = APP.collections.Projects.find(query, options)
    @logProgress "Total documents to be updated: #{initial_affected_docs_count = projects_without_timezone_cursor.count()}"
    while projects_without_timezone_cursor.count() > 0 and @allowedToContinue()
      timezone_to_project = {}

      projects_without_timezone_cursor.forEach (project) ->
        admin_id = project.members[0].user_id
        if (timezone = user_id_to_timezone[admin_id])?
          if timezone_to_project[timezone]?
            timezone_to_project[timezone].push project._id
          else
            timezone_to_project[timezone] = [project._id]
        else
          admin = Meteor.users.findOne
            _id: admin_id
            "profile.timezone":
              $exists: true
          ,
            fields:
              "profile.timezone": 1

          user_id_to_timezone[admin_id] = admin.profile.timezone

      for timezone, project_ids of timezone_to_project
        num_processed += APP.collections.Projects.update
          _id:
            $in: project_ids
        ,
          $set:
            timezone: timezone
        ,
          multi: true

      @logProgress "#{num_processed}/#{initial_affected_docs_count} documents updated"

    if projects_without_timezone_cursor.count() is 0
      @markAsCompleted()

  haltScript: ->
    @logProgress "Halted"
    @disallowToContinue()

    return

  run_if_lte_version_installed: null
