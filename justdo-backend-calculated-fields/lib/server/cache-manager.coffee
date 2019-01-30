_.extend JustdoBackendCalculatedFields.prototype,
  _setupCacheManager: ->
    @enabled_projects_tracker = null
    @enabled_projects_cache = {}

    @_startEnabledProjectsCacheMaintainer()

    return

  _destroyCacheManager: ->
    @_stopEnabledProjectsCacheMaintainer()
    @enabled_projects_cache = {}

    return

  _startEnabledProjectsCacheMaintainer: ->
    @enabled_projects_tracker =
      @projects_collection.find({"conf.custom_features": @options.custom_feature_id}, {fields: {_id: 1}}).observeChanges
        added: (id, fields) =>
          @enabled_projects_cache[id] = true

        removed: (id) =>
          delete @enabled_projects_cache[id]

    return

  _stopEnabledProjectsCacheMaintainer: ->
    @enabled_projects_tracker?.stop()

    return
