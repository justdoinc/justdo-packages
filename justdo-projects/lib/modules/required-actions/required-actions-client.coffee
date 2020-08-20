_.extend PACK.modules.required_actions,
  initClient: ->
    @collection = @options.local_required_actions_collection

    @subscribeGlobalRequiredActions()

    return

  subscribeGlobalRequiredActions: ->
    @logger.debug "Subscribe global required actions"

    return @_setSubscriptionHandle("global_required_actions", Meteor.subscribe("globalRequiredActions"))

  getCursor: (query_options) ->
    if not query_options?
      query_options = {}

    default_options =
      sort:
        date: -1

    query_options = _.extend {}, default_options, query_options

    return @collection.find({}, query_options)

  # Helpers
  activateTaskOnMainTab: (task_id) ->
    gcm = APP.modules.project_page.getCurrentGcm()

    gcm.setPath(["main", "/#{task_id}/"])

    return