_.extend JustdoLicensing.prototype,
  _errors_types:
    _.extend {}, JustdoHelpers.common_errors_types,
      "invalid-license": "Site license invalid"
      "user-license-expired": "User license expired"
      "site-license-expired": "Site license expired"
