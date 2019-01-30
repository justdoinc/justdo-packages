_.extend TasksChangelogManager.prototype,
  _immediateInit: ->
    @_pseudo_custom_fields_tracked_by_simple_tasks_fields_changes_tracker = {}

    @_trackers = {}

    return

  _deferredInit: ->
    #
    # install builtin trackers
    #
    for tracker_name, tracker of PACK.builtin_trackers
      @installTracker(tracker_name, tracker)

    #
    # run startup_trackers
    #
    for startup_tracker in @options?.startup_trackers
      if _.isString startup_tracker
        startup_tracker = [startup_tracker]

      [tracker_name, options] = startup_tracker

      @runTracker(tracker_name, options)

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

  _extractUpdatedByFromModifierOrFail: (modifier) ->
    # Extract the set `updated_by` field from an update operation modifier
    # and returns it.
    # Fails if such an item can't be found by throwing the "updated-by-missing"
    # error.

    if (updated_by = modifier?.$set?.updated_by)?
      return updated_by

    throw @_error "updated-by-missing"

  setupPseudoCustomFieldTrackedBySimpleTasksFieldsChangesTracker: (field, label) ->
    @_pseudo_custom_fields_tracked_by_simple_tasks_fields_changes_tracker[field] = 
      label: label

    return

  getPseudoCustomFieldsTrackedBySimpleTasksFieldsChangesTracker: ->
    return @_pseudo_custom_fields_tracked_by_simple_tasks_fields_changes_tracker

  installTracker: (tracker_name, func) ->
    @_trackers[tracker_name] = (options) =>
      func.call(@, options)

  runTracker: (tracker_name, options) ->
    return @_trackers[tracker_name](options)

  logChange: (obj) ->
    if not obj.by?
      throw @_error "by-field-required"

    @changelog_collection.insert obj, (err) =>
      if err?
        @logger.error(err)

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return