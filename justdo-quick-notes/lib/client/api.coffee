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
          JD.registerPlaceholderItem "quick-notes",
            data:
              template: "justdo_quick_notes_activation_icon"
              template_data: {}

            domain: "global-right-navbar"
            position: 150
          return

        destroyer: =>
          JD.unregisterPlaceholderItem "quick-notes"
          return

    @onDestroy =>
      custom_feature_maintainer.stop()
      return

    return

  # refreshSubscription() takes care of subscribing to publications with options, and stopping the previous subscription
  _refreshSubscription: (publication_name, current_subscription, options, cb) ->
    if not publication_name?
      throw @_error "invalid-argument", "Please specify which publication to subscribe to"

    if not current_subscription?
      return Meteor.subscribe publication_name, options

    prev_subscription = current_subscription
    current_subscription = Meteor.subscribe publication_name, options, cb

    # In case this function is called inside a reactive computation,
    # stop the previous subscription upon the invalidation of the outer computation
    if Tracker.currentComputation?
      Tracker.onInvalidate =>
        prev_subscription.stop()
        return

    Tracker.autorun (computation) ->
      if current_subscription.ready()
        prev_subscription.stop()
        computation.stop()
      return

    return current_subscription

  subscribeQuickNotesInfo: (cb) ->
    if @quick_notes_info_subscribtion?
      @quick_notes_info_subscribtion.stop()
    @quick_notes_info_subscribtion = Meteor.subscribe "quickNotesInfo", cb
    return @quick_notes_info_subscribtion

  # cb is passed directly to the callback of Meteor.subscribe
  # It could either be an object {onReady:(), onStop: ()} or simply a function (which is called on ready)
  subscribeActiveQuickNotes: (options, cb) ->
    if @destroyed
      return

    default_options =
      limit: 0
    options = _.extend default_options, options

    @active_quick_notes_subscription = @_refreshSubscription "activeQuickNotes", @active_quick_notes_subscription, options, cb

    return @active_quick_notes_subscription

  # cb is passed directly to the callback of Meteor.subscribe
  # It could either be an object {onReady:(), onStop: ()} or simply a function (which is called on ready)
  subscribeCompletedQuickNotes: (options, cb) ->
    if @destroyed
      return

    default_options =
      limit: JustdoQuickNotes.completed_quick_notes_subscription_limit
    options = _.defaults options, default_options

    @completed_quick_notes_subscription = @_refreshSubscription "completedQuickNotes", @completed_quick_notes_subscription, options, cb

    return @completed_quick_notes_subscription

  unsubscribeQuickNotesInfo: ->
    if @quick_notes_info_subscribtion?
      @quick_notes_info_subscribtion.stop()
      @quick_notes_info_subscribtion = null
    return

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
