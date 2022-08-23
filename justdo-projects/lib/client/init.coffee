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
      APP.modules.project_page.project_config_ui.registerConfigSection "operations",
        # Add to this section the configs that you want to show first,
        # without any specific title (usually very basic configurations)
        title: "Operations" # null means no title
        priority: 20
        
      APP.modules.project_page.project_config_ui.registerConfigTemplate "create-new-justdo-with-same-settings",
        section: "operations"
        template: "create_new_justdo_with_same_settings"
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "create_new_justdo_with_same_settings_project_config",
        section: "extensions"
        template: "create_new_justdo_with_same_settings_project_config"
        priority: 100

      return

    return