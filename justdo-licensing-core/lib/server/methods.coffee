_.extend JustdoLicensing.prototype,
  _setupMethods: ->
    self = @

    if not _.has Meteor.default_server.method_handlers, "getLicense"
      Meteor.methods
        "getLicense": ->
          check @userId, String

          APP.justdo_site_admins.requireUserIsSiteAdmin @userId

          return self.getLicense()

      return
