_.extend JustdoQuickNotes.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()
    @_setupSubscriptions()

    return

  _setupSubscriptions: ->
    @_non_completed_quick_notes_subscription = Meteor.subscribe "activeQuickNotes"
    @_completed_quick_notes_subscription = Meteor.subscribe "completedQuickNotes"
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
      if self._non_completed_quick_notes_subscription?
        self._non_completed_quick_notes_subscription.stop()
      if self._completed_quick_notes_subscription?
        self._completed_quick_notes_subscription.stop()
      return

    return
