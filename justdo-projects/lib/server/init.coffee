_.extend Projects.prototype,
  _init: ->
    # Defined in hooks.coffee
    @_setupHooks()

    # Defined in collections_indices.coffee
    @_ensureIndicesExists()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in db-migrations.coffee
    @_setupDbMigrations()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in grid-control-middlewares.coffee
    @_setupGridControlMiddlewares()

    # Init projects plugins cache
    @_initProjectsPluginsCache()