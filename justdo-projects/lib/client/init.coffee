_.extend Projects.prototype,
  _init: ->
    @_subscriptions_handles = {}

    # Defined in subscriptions.coffee
    @_setupSubscriptions()
    @_setupProjectRemovalProcedures()

    # Defined in hash-requests.coffee
    @_setupHashRequests()
