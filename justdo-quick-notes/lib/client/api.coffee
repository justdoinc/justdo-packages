_.extend JustdoQuickNotes.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    self = @
    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()
    @onDestroy =>
      self.unsubscribeActiveQuickNotes()
      self.unsubscribeCompletedQuickNotes()
      return

    return

  setupCustomFeatureMaintainer: ->
    self = @
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoQuickNotes.project_custom_feature_id,
        installer: =>
          return

        destroyer: =>
          return

    @onDestroy =>
      custom_feature_maintainer.stop()
      return

    return

  # refreshSubscription() takes care of subscribing to publications with options, and stopping the previous subscription
  _refreshSubscription: (publication_name, current_subscription, options, onSubscriptionReadyCb) ->
    if not publication_name?
      throw @_error "invalid-argument", "Please specify which publication to subscribe to"

    if not current_subscription?
      return Meteor.subscribe publication_name, options

    prev_subscription = current_subscription
    current_subscription = Meteor.subscribe publication_name, options

    Tracker.autorun (computation) ->
      if current_subscription.ready()
        onSubscriptionReadyCb?()
        prev_subscription.stop()
        computation.stop()
      return

    return current_subscription

  subscribeActiveQuickNotes: (options, cb) ->
    if @destroyed
      return

    default_options =
      limit: 0
    options = _.defaults options, default_options

    @active_quick_notes_subscription = @_refreshSubscription "activeQuickNotes", @active_quick_notes_subscription, options, onSubscriptionReadyCb

    return @active_quick_notes_subscription

  subscribeCompletedQuickNotes: (options, cb) ->
    if @destroyed
      return

    default_options =
      limit: JustdoQuickNotes.completed_quick_notes_subscription_limit
    options = _.defaults options, default_options

    @completed_quick_notes_subscription = @_refreshSubscription "completedQuickNotes", @completed_quick_notes_subscription, options, onSubscriptionReadyCb

    return @completed_quick_notes_subscription

  unsubscribeActiveQuickNotes: ->
    if @active_quick_notes_subscription?
      @active_quick_notes_subscription.stop()
      @active_quick_notes_subscription = null
    return

  unsubscribeCompletedQuickNotes: ->
    if @completed_quick_notes_subscription?
      @completed_quick_notes_subscription.stop()
      @completed_quick_notes_subscription = null
    return
