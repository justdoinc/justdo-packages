_.extend JustdoAccounts.prototype,
  requireLogin: ->
    user_id = Tracker.nonreactive ->
      Meteor.userId()

    if not user_id?
      throw @_error "login-required"

    return true

  getUserPublicInfo: (options, cb) ->
    Meteor.call "getUserPublicInfo", options, cb

  getFirstLastNameByEmails: (emails, options, cb) ->
    Meteor.call "getFirstLastNameByEmails", emails, options, cb

    return

  userExists: (email, cb) ->
    Meteor.call "userExists", email, cb

  createProxyUsers: (options, cb) ->
    Meteor.call "justdoAccountsCreateProxyUsers", options, cb
    return

  createUser: (options, cb) ->
    # The following is mostly a coffee version of Account.createUser
    # version v1.1.0.3-justdo-meteor-future-1

    if Meteor.userId()?
      cb(@_error("login-already", "Can't register a new user once user is already logged in"))

      return

    options = _.clone(options) # we'll be modifying options

    if typeof options.password != 'string'
      throw new Error('options.password must be a string')
    if not options.password
      cb(new Meteor.Error(400, 'Password may not be empty'))

      return

    # Replace password with the hashed password.
    options.password = Accounts._hashPassword(options.password)

    @emit "user-signup", options

    Meteor.call "justdoAccountsCreateUser", options, cb

  signLegalDocs: (legal_docs, cb) ->
    Meteor.call "signLegalDocs", legal_docs, cb

  sendVerificationEmail: (cb) ->
    @requireLogin()

    Meteor.call "sendVerificationEmail", cb

  sendPasswordResetEmail: (email, cb) ->
    Meteor.call "sendPasswordResetEmail", email, cb

  syncUserTimezone: (cb) ->
    tz = moment.tz.guess()

    existing_user_tz = Tracker.nonreactive ->
      # nonreactive since we don't want any change to user
      # to trigger invalidation
      Meteor.user()?.profile?.timezone

    if not existing_user_tz? or existing_user_tz != tz
      Meteor.call "setUserTimezone", tz, cb

      @logger.debug "timezone: User timezone synced"
    else
      @logger.debug "timezone: No need to sync user timezone"

  isPasswordFlowPermittedForUser: (email, cb) ->
    Meteor.call "isPasswordFlowPermittedForUser", email, cb

  editPreEnrollmentUserData: (user_id, data, cb) ->
    Meteor.call "editPreEnrollmentUserData", user_id, data, cb

  changeAccountEmail: (email, password, cb) ->
    Meteor.call "changeAccountEmail", email, password, cb
