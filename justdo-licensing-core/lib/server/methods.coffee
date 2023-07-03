_.extend JustdoLicensing.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      "getLicense": ->
        check @userId, String

        APP.justdo_site_admins.requireUserIsSiteAdmin @userId

        return self.getLicense()

    return
