passwordValidator = Match.OneOf(
  String,
  { digest: String, algorithm: String }
)

_.extend JustdoAccounts.prototype,
  _setupMethods: ->
    accounts_object = @

    Meteor.methods
      getUserPublicInfo: (options) ->
        check(options, JustdoAccounts.get_user_public_info_options_schema)

        return accounts_object.getUserPublicInfo options, @userId

      userExists: (email) ->
        check(email, String)

        return accounts_object.userExists email, @userId

      justdoAccountsCreateUser: (options) ->
        # For justdoAccountsCreateUser requests received from client, password
        # option must be set, and must not be plain text

        # We currently don't support username option, we reject it
        # if we find it

        # accounts_object.createUser makes sure options.profile
        # follows our standard for profiles.

        # The "justdoAccounts" prefix of this method is since createUser already taken
        # by Meteor

        # Read accounts_object.createUser for full documentation.

        if not options?
          throw accounts_object._error("missing-argument")

        if not options.password?
          throw accounts_object._error("password-must-be-set-for-client-create-user")

        if _.isString(options.password)
          throw accounts_object._error("plain-text-password-on-wire-forbidden")

        # note, from here on, we rely on accounts_object.createUser
        # to keep validating options.password and the rest of the options
        # (accounts_object.createUser allows plain text uesr creation, hence
        # that's the only thing we have to check here)

        return accounts_object.createUser options, @userId

      signLegalDocs: (legal_docs_signed) ->
        check(legal_docs_signed, [String])

        return accounts_object.signLegalDocs legal_docs_signed, @userId

      sendVerificationEmail: ->
        return accounts_object.sendVerificationEmail @userId

      sendPasswordResetEmail: (email) ->
        check(email, String)

        if not JustdoHelpers.common_regexps.email.test(email)
          throw @_error("invalid-email")

        return accounts_object.sendPasswordResetEmail email, @userId

      setUserTimezone: (timezone) ->
        check(timezone, String)

        return accounts_object.setUserTimezone timezone, @userId

      accounts_avatars_getAvatarUploadPolicy: ->
        return accounts_object.getAvatarUploadPolicy @userId

      accounts_avatars_setFilestackAvatar: (filestack_url, policy) ->
        return accounts_object.setFilestackAvatar filestack_url, policy, @userId

      isPasswordFlowPermittedForUser: (email) ->
        return accounts_object.isPasswordFlowPermittedForUser email

      editPreEnrollmentUserData: (user_id, data) ->
        check user_id, String
        check data, Object # Data is thoroughly verified by editPreEnrollmentUserData

        return accounts_object.editPreEnrollmentUserData user_id, data, @userId

      changeAccountEmail: (email, password) ->
        check email, String
        check password, passwordValidator

        return accounts_object.changeAccountEmail email, password, @userId
      
      registerAsPromoter: (description) ->
        check description, String
        return accounts_object.registerAsPromoter description, @userId
