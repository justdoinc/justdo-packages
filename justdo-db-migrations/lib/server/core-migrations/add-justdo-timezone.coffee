batch_timeout = null
clearTimeout = ->
  if batch_timeout?
    Meteor.clearTimeout batch_timeout
    batch_timeout = null

    @logProgress "Batch processing timeout cleared"

  return

APP.justdo_db_migrations.registerMigrationScript "justdo-timezone",
  runScript: ->
    batch_size = 100
    delay_between_batches = 1000
    user_id_to_timezone = {} # Caches queried admin timezones

    fallback_timezone = moment.tz.guess()

    # The two var below are solely for logging progress
    initial_affected_docs_count = 0
    num_processed = 0

    query =
      timezone:
        $exists: false

      members:
        $elemMatch:
          is_admin: true # To ensure we act only on JustDos that has admins

    options =
      fields:
        members:
          $elemMatch:
            is_admin: true
      limit: batch_size

    projects_without_timezone_cursor = APP.collections.Projects.find(query, options)

    initial_affected_docs_count = projects_without_timezone_cursor.count() # Note: count ignores limit
    @logProgress "Total documents to be updated: #{initial_affected_docs_count}"

    processBatchWrapper = => 
      try
        processBatch()
      catch e
        @logProgress "Error found halt the script", e

        @halt()

      return

    processBatch = =>
      if not @isAllowedToContinue()
        return

      if projects_without_timezone_cursor.count() == 0
        @markAsCompleted()
        return

      timezone_to_project = {}

      projects_without_timezone_cursor.forEach (project) ->
        admin_id = project.members[0].user_id
        if not (timezone = user_id_to_timezone[admin_id])?
          admin = Meteor.users.findOne
            _id: admin_id
            "profile.timezone":
              $exists: true
          ,
            fields:
              "profile.timezone": 1

          timezone = admin?.profile?.timezone or fallback_timezone

          user_id_to_timezone[admin_id] = timezone

        if timezone_to_project[timezone]?
          timezone_to_project[timezone].push project._id
        else
          timezone_to_project[timezone] = [project._id]

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

      @logProgress "Waiting #{delay_between_batches / 1000}sec before starting the next batch"
      batch_timeout = Meteor.setTimeout =>
        processBatchWrapper()
      , delay_between_batches

      return

    Meteor.defer ->
      # To avoid running in the original tick that called the necessary db-migrations, defer the run
      processBatchWrapper()

      return

    return

  haltScript: ->
    clearTimeout.call(@)

    return

  run_if_lte_version_installed: null
