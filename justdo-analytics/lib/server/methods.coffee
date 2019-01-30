_.extend JustdoAnalytics.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      JAConnect: (identification_object) ->
        return self.connect identification_object

      JA: (log) ->
        return self.log log

      JAReportClientSideError: (error_type, val) ->
        return self.logClientSideError(error_type, val)

    return
