_.extend Projects.prototype,
  _init: ->
    @_subscriptions_handles = {}

    # Defined in subscriptions.coffee
    @_setupSubscriptions()
    @_setupProjectRemovalProcedures()

    # Defined in hash-requests.coffee
    @_setupHashRequests()

    # Users related
    @initEncounteredUsersIdsTracker()
    @initEncounteredUsersIdsPublicBasicUsersInfoFetcher()

    # Defined in drawer-menu-items.coffee
    @_registerDrawerPlaceholders()

    return
