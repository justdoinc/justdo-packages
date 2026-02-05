_.extend Projects.prototype,
  _init: ->
    @_subscriptions_handles = {}

    # Defined in subscriptions.coffee
    @_setupSubscriptions()
    @_setupProjectRemovalProcedures()

    # Users related
    @initEncounteredUsersIdsTracker()
    @initEncounteredUsersIdsPublicBasicUsersInfoFetcher()

    # Defined in drawer-menu-items.coffee
    @_registerDrawerPlaceholders()

    # Defined in api.coffee
    @_setupEventHooks()
    @_setupPushNotificationsHandlers()

    return
