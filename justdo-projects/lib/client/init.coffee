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

    APP.executeAfterAppClientCode ->
      console.log 'register'
      APP.modules.project_page.project_config_ui.registerConfigTemplate "create-new-justdo-with-same-settings",
        section: "create-new-justdo-with-same-settings"
        template: "create_new_justdo_with_same_settings"
        priority: 1001

      return

    return