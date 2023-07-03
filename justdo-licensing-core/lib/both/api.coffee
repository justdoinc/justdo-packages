_.extend JustdoLicensing.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  limited_license_schema: new SimpleSchema
    permitted_domain:
      type: String

    max_version:
      type: String

      optional: true

    grace_period_ends:
      type: String

    valid_until:
      type: String

    paid_users:
      type: Number

  unlimited_license_schema: new SimpleSchema
    permitted_domain:
      type: String

    max_version:
      type: String

      optional: true

    unlimited:
      type: Boolean

      allowedValues: [true]

  isUserExcluded: (user) ->
    for email in user.emails
      if email.address.split("@")[1] in JustdoLicensing.excluded_domains
        return true
    return false
