_.extend JustdoLicensing.prototype,
  _immediateInit: ->
    @_setupOnLoginHandler()

    @license = @parseSingleQuotedJson(@options.jsoned_license)

    @requireValidLicense()

    return

  parseSingleQuotedJson: (single_quoted_json) ->
    return EJSON.parse(single_quoted_json.replace(/'/g, '"'))

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  _setupOnLoginHandler: ->
    self = @
    APP.on "pre-login", (user_id) ->
      self.requireValidLicense()

      user_license = self.isUserLicensed user_id

      if not user_license.licensed
        throw self._error "user-license-expired", "User license expired"

      return true

  requireValidLicense: (obj) ->
    if not obj?
      obj = @license

    if obj.unlimited is true
      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          @unlimited_license_schema,
          obj,
          {self: @, throw_on_error: true}
        )
    else
      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          @limited_license_schema,
          obj,
          {self: @, throw_on_error: true}
        )

    obj = cleaned_val

    if moment(obj.valid_until, "YYYY-MM-DD") < moment()
      throw @_error "site-license-expired"

    if obj.max_version?
      # If APP_VERSION is v3.137.3-3-g599c2a30, matched_current_version will be ["3", "137", "3"]
      matched_license_version = obj.max_version.match(JustdoLicensing.max_version_regex).slice(1, 4)
      matched_current_version = process.env.APP_VERSION.match(JustdoLicensing.max_version_regex).slice(1, 4)
      for current_version, i in matched_current_version
        current_version = parseInt current_version, 10
        license_version = parseInt matched_license_version[i], 10
        if current_version > license_version
          throw @_error "not-supported", "Max licensed version is #{obj.max_version}, but #{process.env.APP_VERSION} is installed."
        else
          break

    if obj.permitted_domain isnt (new JustdoHelpers.url.URL process.env.LANDING_APP_ROOT_URL).hostname
      throw @_error "invalid-license"

    return

  getLicense: ->
    return @license

  isUserLicensed: (user_id) ->
    license = @getLicense()

    if (license.unlimited)
      return {licensed: true}

    user = Meteor.users.findOne user_id, {fields: {deactivated: 1, createdAt: 1, site_admin: 1, emails: 1}}
    licensed_user_count = license.paid_users

    if APP.justdo_licensing.isUserExcluded user
      return {licensed: true, type: "excluded"}

    if user.deactivated
      return {licensed: true, type: "deactivated"}

    site_admin_query =
      "site_admin.is_site_admin": true
      "emails.address":
        $not: @getRegexForExcludedEmailDomains()

    # If current user is site admin,
    # simply determine whether the amount of site admins created on or before the current user is lte to licensed_user_count
    if user.site_admin?.is_site_admin
      site_admin_query.createdAt =
        $lte: user.createdAt

      if Meteor.users.find(site_admin_query).count() <= licensed_user_count
        return {licensed: true}
    # Else we query for the amount of users created on or before the the current user,
    # and see if the amount is larger than the difference of licensed_user_count and site_admins_count
    # i.e. (amount of users created on or before current user) <= (licensed_user_count - site_admins_count)
    else
      if (site_admins_count = Meteor.users.find(site_admin_query).count()) <= licensed_user_count
        #
        # IMPORTANT, if you change is_licensed_query, don't forget to update the collections-indexes.coffee
        # and to drop obsolete indexes (see IS_USER_LICENSED_INDEX)
        #
        is_licensed_query =
          deactivated:
            $ne: true
          "site_admin.is_site_admin":
            $ne: true
          "emails.address":
            $not: @getRegexForExcludedEmailDomains()
          createdAt:
            $lte:
              user.createdAt

        is_licensed_options =
          sort:
            createdAt: 1
          limit:
            licensed_user_count + 1

        is_licensed = Meteor.users.find(is_licensed_query, is_licensed_options).count() <= (licensed_user_count - site_admins_count)

        if is_licensed
          return {licensed: true}

    # If a user falls to here, it means the user is not licensed.
    # We then determine whether the user is under grace period.
    user_grace_period_ends = moment(user.createdAt).add(JustdoLicensing.new_users_grace_period, "days")
    license_grace_period_ends = moment(license.grace_period_ends, "YYYY-MM-DD")

    if (furthest_grace_period = moment(Math.max user_grace_period_ends, license_grace_period_ends)) >= moment()
      if furthest_grace_period.format() is user_grace_period_ends.format()
        type = "new-users-grace-period"
      else
        type = "license-grace-period"

      return {licensed: true, type: type, expire: furthest_grace_period}

    return {licensed: false}

  getRegexForExcludedEmailDomains: ->
    regex = []

    for domain in JustdoLicensing.excluded_domains
      regex.push "(.+@#{JustdoHelpers.escapeRegExp domain})"

    regex = new RegExp regex.join "|"

    return regex
