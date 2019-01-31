_.extend JustdoAnalytics.prototype,
  _setupPublications: ->
    @setupJAEnabledAnnouncementPublication()

    return

  setupJAEnabledAnnouncementPublication: ->
    self = @

    Meteor.publish null, ->
      @added('JAEnabled', "0", {})

      @ready()

    return 