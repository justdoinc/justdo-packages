_.extend MeetingsManagerPlugin.prototype,
  _immediateInit: ->
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

    Projects.registerAllowedConfs
      "block_meetings_deletion":
        require_admin_permission: true
        value_matcher: Boolean
        allow_change: true
        allow_unset: true

    return