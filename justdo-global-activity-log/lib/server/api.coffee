default_global_changelog_tasks_limit = JustdoGlobalActivityLog.default_global_changelog_tasks_limit
default_global_changelog_changelogs_limit = JustdoGlobalActivityLog.default_global_changelog_changelogs_limit

_.extend JustdoGlobalActivityLog.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

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

  _globalChangelogPublicationHandlerOptionsSchema: new SimpleSchema
    changelog_time_frame_ms:
      # Set to null/undefined if you don't want any time_frame limit for the
      # returned Changelog items

      type: Number

      min: 60 * 1000 # 1 min

      optional: true

      defaultValue: null # 5 * 24 * 60 * 60 * 1000 # 5 days

    tasks_limit:
      type: Number

      defaultValue: default_global_changelog_tasks_limit

      min: 1

    changelogs_limit:
      type: Number

      defaultValue: default_global_changelog_changelogs_limit

      min: 1

    include_performing_user:
      type: Boolean

      defaultValue: false

    projects:
      # If set to null, we fetch from all projects
      #
      # At the moment we support one and only single project
      type: [String]

      defaultValue: null

    query_field:
      type: [String]
      optional: true

  globalChangelogPublicationHandler: (publish_this, options, performing_user_id) ->
    @requireUserProvided(performing_user_id)

    if not options?
      options = {}

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_globalChangelogPublicationHandlerOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    if options.projects.length > 1
      throw @_error "invalid-options", "projects option support a single project at the moment"

    project_id = options.projects[0]

    # Tasks that been updated by the current user have high
    # chance to contain only changes by that user, if options.include_performing_user
    # is set to false that means, that if the performing_user is very active - he
    # won't see any changes for all the tasks returned by tasks query (since all might
    # have been done by him for these tasks, and they are getting excluded).
    # Therefore, we divide the tasks_limit by 2 to ensure at least half of the result -
    # haven't been performed by the performing user - and at least some changes will
    # be returned.
    #
    # Also, keep in mind, the updated_by tells us only who did the last change, it is possible
    # that right before that change been made, another user performed another change, therefore
    # even if include_performing_user option is set to false, we still need to show fetch
    # tasks recently changed by the current user (that's why we keep the 50:50 blend)
    tasks_query =
      users: performing_user_id
      project_id: project_id

    if (changelog_time_frame_ms = options.changelog_time_frame_ms)?
      tasks_query._raw_updated_date = {$gte: JustdoHelpers.getDateMsOffset(-1 * changelog_time_frame_ms)}

    tasks_options =
      fields:
        _id: 1
      sort:
        _raw_updated_date: -1

    recently_updated_tasks_ids =
      @tasks_collection.find(tasks_query, tasks_options).map (task) -> task._id

    changelog_query =
      task_id: {$in: recently_updated_tasks_ids}
      change_type: {$ne: "users_change"}

    if (changelog_time_frame_ms = options.changelog_time_frame_ms)?
      changelog_query.when = {$gte: JustdoHelpers.getDateMsOffset(-1 * changelog_time_frame_ms)}

    if not options.include_performing_user
      changelog_query.by = {$ne: performing_user_id}

    if options.query_field
      changelog_query.field = {$in: options.query_field}

    changelog_options =
      limit: options.changelogs_limit
      sort:
        when: -1

    target_col_name = JustdoGlobalActivityLog.global_changelog_collection_name
    @tasks_changelog_collection.find(changelog_query, changelog_options).forEach (changelog_doc) ->
      publish_this.added target_col_name, changelog_doc._id, changelog_doc

      return

    publish_this.ready()

    return
