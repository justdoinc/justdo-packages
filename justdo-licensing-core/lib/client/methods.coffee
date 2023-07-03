_.extend JustdoLicensing.prototype,
  getLicenseFromServer: (cb) ->
    Meteor.call "getLicense", cb

    return
