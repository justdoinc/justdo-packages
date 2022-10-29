# BEGIN CODE TAKEN FROM Meteor's accounts-password: passowrd_server.js

bcrypt = NpmModuleBcrypt
bcryptHash = Meteor.wrapAsync(bcrypt.hash)

getPasswordString = (password) ->
  if typeof password == 'string'
    password = SHA256(password)
  else
    # 'password' is an object
    if password.algorithm != 'sha-256'
      throw new Error('Invalid password hash algorithm. ' + 'Only \'sha-256\' is allowed.')
    password = password.digest

  return password

hashPassword = (password) ->
  password = getPasswordString(password)

  return bcryptHash(password, Accounts._bcryptRounds())

# END

_.extend JustdoAccounts.prototype,
  requireLogin: (user_id) ->
    if not user_id?
      throw @_error "login-required"

    check(user_id, String)

    return true

  getUserById: (user_id) -> Meteor.users.findOne(user_id)

  getUserByEmail: (email) ->
    check(email, String)

    return Accounts.findUserByEmail(email)

  _passwordSetInUserObj: (user_obj) ->
    return user_obj?.services?.password?.bcrypt?

  getUserPublicInfo: (options={}) ->
    # XXX one day we'll need to base this one on
    # findOnePublicBasicUserInfo()
    #
    # Returns null if user doesn't exist, otherwise properties
    # from his profile that we consider to be public
    # if non of the public properies are set for that user, an
    # empty object will return.

    # Since we need this function during registration/login
    # process we don't require login

    check(
      JustdoAccounts.get_user_public_info_options_schema.clean(options),
      JustdoAccounts.get_user_public_info_options_schema
    )

    if not (user_obj = @getUserByEmail(options.email))?
      return null

    if options.ignore_invited and not user_obj.is_proxy
      # ignore_invited #
      # If set to true, we will regard users that been invited but haven't
      # registered yet as non-existing.

      # is_proxy #
      # Treat proxy users as existing user without profile object,
      # so that landing app will force them to setup their first password by clicking "Forgot password"

      if not @userCompletedRegistration(user_obj)
        return null

    if not (profile = user_obj.profile)?
      # Existing user, missing profile object
      return {}

    picked_profile = _.pick(profile, "profile_pic")

    return {profile: picked_profile}

  getFirstLastNameByEmails: (emails, options, perform_as) ->
    # perform_as and options are for potential future uses, as of now they are ignored

    if _.isString emails 
      emails = [emails]

    check emails, [String]
    check options, Object

    users_docs = JustdoHelpers.getUsersByEmail(emails, {query_options: {fields: {"emails.address": 1, "profile.first_name": 1, "profile.last_name": 1, is_proxy: 1}}})

    result = {}

    for user_doc in users_docs
      for email_def in user_doc.emails
        if emails.indexOf(email_def.address) > -1
          result[email_def.address] =
            _id: user_doc._id
            first_name: user_doc.profile.first_name
            last_name: user_doc.profile.last_name
            is_proxy: user_doc.is_proxy

    return result

  userCompletedRegistration: (user_obj) ->
    if @_passwordSetInUserObj(user_obj)
      return true

    # If the user has services other than email, resume and password, we assume he
    # completed registration using these services
    if _.difference(_.keys(user_obj.services), ["resume", "password", "email"]).length > 0
      return true

    return false

  isPasswordFlowPermittedForUser: (email) ->
    # Once a user completed registration for the first time with
    # a service different than the password service, this method
    # will return false.
    #
    # This will let the login control know that it should prevent
    # the password flow from taking place, since this user doesn't
    # have a password - and is unable to use this flow.
    #
    # This will also allow the user preferences dialog in the web
    # app know that this user doesn't have a password set, and
    # should be allowed to define one without entering his current
    # password.
    #
    # Once the user will define a password, he'll be able to start
    # using the password flow as well as any other service he have
    # registered with.

    if not (user_obj = @getUserByEmail(email))?
      throw @_error("unknown-user")

    if @userCompletedRegistration(user_obj)
      # Show password prompt for proxy users and force them to click "Forget Password" to setup their first password.
      if not @_passwordSetInUserObj(user_obj) and not user_obj.is_proxy
        return false

    return true

  userExists: (email) ->
    # Returns true if a user with the given email exists in the system

    return @getUserPublicInfo({email: email})?

  createProxyUsers: (users_options, inviting_user_id) ->
    check users_options, Array
    created_user_ids = []

    # Checking phase
    for user_options in users_options
      if not (profile = user_options.profile)?
        throw @_error("profile-missing")

      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          JustdoAccounts.user_profile_schema,
          profile,
          {self: @, throw_on_error: true}
        )
      user_options.profile = cleaned_val

      if user_options.username?
        throw @_error("username-not-supported")

      if not user_options.email? or not JustdoHelpers.common_regexps.email.test(user_options.email)
        throw @_error("invalid-email")

      if Accounts.findUserByEmail(user_options.email)?
        throw @_error("user-already-exists")

    for user_options in users_options
      if inviting_user_id?
        user_options.invited_by = inviting_user_id
      user_options.is_proxy = true
      APP.emit("before-create-user", user_options)
      created_user_id = Accounts.createUser user_options
      created_user_ids.push created_user_id
      APP.emit("after-create-user", {email: user_options.email, created_user_id: created_user_id})

    return created_user_ids

  createUser: (options, inviting_user_id) ->
    # Creates and initiate a new user with the given options
    #
    # Notes:
    #
    #   * existence of inviting_user_id won't be checked
    #
    #   * options are the same options expected by Accounts.createUser with
    #     the following extensions/changes:
    #
    #       * username is not supported by this package
    #       * signed_legal_docs if set, has to pass @requireLegalDocsExist(), will be passed to @signLegalDocs
    #       * send_verification_email, if exists and is true, sendVerificationEmail will be called after account creation
    #
    #   * options.profile is required, will have to comply with JustdoAccounts.user_profile_schema
    #
    # Returnes the created user id.

    if not (profile = options.profile)?
      throw @_error("profile-missing")

    check(JustdoAccounts.user_profile_schema.clean(profile), JustdoAccounts.user_profile_schema)

    if options.username?
      throw @_error("username-not-supported")

    if not options.email? or not JustdoHelpers.common_regexps.email.test(options.email)
      throw @_error("invalid-email")

    if (signed_legal_docs = options.signed_legal_docs)?
      @requireLegalDocsExist(signed_legal_docs)

    user_obj = @getUserByEmail(options.email)
    if not user_obj?
      if inviting_user_id?
        options.invited_by = inviting_user_id
      APP.emit("before-create-user", options)

      created_user_id = Accounts.createUser options

      APP.emit("after-create-user", {email: options.email, created_user_id: created_user_id})
    else
      if @userCompletedRegistration(user_obj) or user_obj.is_proxy
        # If the user already completed the registration process using
        # password or OAuth services that we support, don't allow using
        # the createUser process to affect the user doc.
        throw @_error("user-already-exists")

      # If the user exists but haven't registered (or completed enrollment)
      # yet (can happen if user didn't respond to enrollment invitation)
      # allow using createUser to setup the user.

      # In the process we will revoke existing entrollment tokens.

      created_user_id = user_obj._id

      if not options.password?
        @_error("missing-argument", "options.password must be set for enrolled user")
      hashed_password = hashPassword(options.password)

      # We need to set profile ourself and password
      # And revoke existing enrollments
      Meteor.users.update created_user_id,
        $set:
          "profile": options.profile
          "services.password.bcrypt": hashed_password
        $unset:
          "services.password.reset": 1

    if signed_legal_docs?
      @signLegalDocs(signed_legal_docs, created_user_id)

    extra_fields = _.extend {}, @options.new_accounts_custom_fields

    check options.users_allowed_to_edit_pre_enrollment, Match.Maybe([String])
    if options.users_allowed_to_edit_pre_enrollment? and not _.isEmpty(options.users_allowed_to_edit_pre_enrollment)
      Meteor.users.update(created_user_id, {$set: {users_allowed_to_edit_pre_enrollment: options.users_allowed_to_edit_pre_enrollment}})

    if not _.isEmpty extra_fields
      Meteor.users.update(created_user_id, {$set: extra_fields})

    if options.send_verification_email == true
      @sendVerificationEmail(created_user_id)

    return created_user_id

  requireLegalDocsExist: (legal_docs_signed) ->
    # Throw "unknown-legal-doc" error if any of the legal_docs_signed
    # doesn't exist
    check(legal_docs_signed, [String])

    for legal_doc_name in legal_docs_signed
      if not (JustdoLegalDocsVersions[legal_doc_name])?
        throw @_error("unknown-legal-doc", "Unknown legal doc #{legal_doc_name}")

    return

  signLegalDocs: (legal_docs_signed, user_id) ->
    check(legal_docs_signed, [String])

    if _.isEmpty(legal_docs_signed)
      return # nothing to do

    @requireLegalDocsExist(legal_docs_signed)

    @requireLogin(user_id)

    if not (user_obj = @getUserById(user_id))?
      throw @_error("unknown-user")

    if not (current_signed_legal_docs = user_obj.signed_legal_docs)?
      current_signed_legal_docs = {}

    new_signed_legal_docs = {}

    for legal_doc_name in legal_docs_signed
      # Note Including the legal doc issuance date as part of the info saved to
      # the user doc, instead of the version alone as a string val is an historical
      # mistake, that we endure for now.
      version = _.pick JustdoLegalDocsVersions[legal_doc_name], "version", "date"

      new_signed_legal_docs[legal_doc_name] =
        datetime_signed: new Date()
        version: version

    new_signed_legal_docs =
      _.extend {},
               current_signed_legal_docs,
               new_signed_legal_docs

    Meteor.users.update user_id,
      $set:
        signed_legal_docs: new_signed_legal_docs

    return

  sendVerificationEmail: (user_id) ->
    @requireLogin(user_id)

    if not (user_obj = @getUserById(user_id))?
      throw @_error("unknown-user")

    if not (email_details = user_obj.emails?[0])?
      throw @_error("no-email-associated-with-user")

    if email_details.verified == true
      throw @_error("user-already-verified")

    email = email_details.address

    # Check whether verification token already exists
    verification_token = null
    existing_verification_tokens =
      user_obj.services?.email?.verificationTokens
    if existing_verification_tokens
      for token in existing_verification_tokens
        if token.address == email
          verification_token = token.token

          break

    if not verification_token?
      # If no verification token exists create a new one

      verification_token = Random.secret()

      token_record =
        token: verification_token
        address: email
        when: new Date

      Meteor.users.update user_id, {
        $push: {
          "services.email.verificationTokens": token_record
        }
      }

    landing_app_root_url =
      process.env.LANDING_APP_ROOT_URL or process.env.ROOT_URL

    verification_link = "#{landing_app_root_url}/#/verify-email/#{verification_token}"

    Meteor.defer ->
      JustdoEmails.buildAndSend
        to: email
        template: "email-verification"
        template_data:
          first_name: user_obj.profile?.first_name
          verification_link: verification_link
          landing_app_root_url: landing_app_root_url

    return true

  sendPasswordResetEmail: (email) ->
    if not (user_obj = @getUserByEmail(email))?
      throw @_error("unknown-user")

    # Check whether reset token already exists
    reset_token = user_obj.services?.password?.reset?.token

    if not reset_token?
      # If no reset token exists create a new one

      reset_token = Random.secret()

      token_record =
        token: reset_token
        email: email
        when: new Date
        reason: 'reset' # Future ready Meteor PR #7817

      Meteor.users.update user_obj._id, {
        $set: {
          "services.password.reset": token_record
        }
      }

    landing_app_root_url =
      process.env.LANDING_APP_ROOT_URL or process.env.ROOT_URL

    reset_link = "#{landing_app_root_url}/#/reset-password/#{reset_token}"

    Meteor.defer ->
      JustdoEmails.buildAndSend
        to: email
        template: "password-recovery"
        template_data:
          first_name: user_obj.profile?.first_name
          reset_link: reset_link
          landing_app_root_url: landing_app_root_url

    return true

  setUserTimezone: (timezone, user_id) ->
    @requireLogin(user_id)

    Meteor.users.update user_id, {
      $set: {
        "profile.timezone": timezone
      }
    }

  getAvatarUploadPolicy: (user_id) ->
    if not Match.test user_id, String
      throw @_error "expected-string", "Expected user_id to be a string"
    if not Match.test Meteor.users.findOne(user_id), Object
      throw @_error "expected-user", "Expected user to exist."

    signature = APP.filestack_base.signPolicy
      call: ['pick', 'store', 'convert', 'remove']
      path: @_getAvatarUploadPath(user_id)
      expiry: Date.now() / (1000 + 60) * 30 # 30 minutes (to account for any clock mismatches)

    return {
      signature: signature.hmac
      policy: signature.encoded_policy
    }

  setFilestackAvatar: (filepicker_blob, policy, user_id) ->
    # XXX We should verify the policy here to ensure that the user who is
    # fetching the direct url is the same as the user who uploaded the file
    # this shouldn't have any direct security implications because user
    # avatars are public anyway (and other files are private), but should be
    # checked for consistentcy and to prevent a loop hole opening up later.
    if not Match.test user_id, String
      throw @_error "expected-string", "Expected user_id to be a string"
    if not Match.test Meteor.users.findOne(user_id), Object
      throw @_error "expected-user", "Expected user to exist."

    if not Match.test filepicker_blob, Object
      throw @_error "expected-object", "Expected filepicker_blob to be an object."

    filepicker_blob = _.pick filepicker_blob, "url"

    if not Match.test filepicker_blob.url, String
      throw @_error "expected-string", "Expected filepicker_blob.url to be a string."

    filepicker_url = filepicker_blob.url
    handle = filepicker_blob.id = APP.filestack_base.getHandle filepicker_url
    signed_policy = APP.filestack_base.signPolicy
      handle: handle
      call: ['stat']
      expiry: Date.now() / (1000 + 60) * 30 # 30 minutes (to account for any clock mismatches)

    result = HTTP.get "https://www.filestackapi.com/api/file/#{handle}/metadata?key=#{@options.api_key}&policy=#{signed_policy.encoded_policy}&signature=#{signed_policy.hmac}"

    metadata = result.data

    pathEncodeURIComponent = (path) -> _.map(path.split("/"), (part) -> encodeURIComponent(part)).join("/")

    url = "https://#{metadata.container}.s3.amazonaws.com/#{pathEncodeURIComponent(metadata.path)}"

    #
    # Make a copy with proper cache header
    #
    copy_params =
      CopySource: "#{metadata.container}/#{pathEncodeURIComponent(metadata.key)}"
      # Target
      ACL: "public-read"
      Bucket: metadata.container
      Key: metadata.key
      ContentType: metadata.mimetype
      MetadataDirective: "REPLACE"
      CacheControl: "public, max-age=31536000"
      # 31536000 is 1 year see: http://stackoverflow.com/a/3001556/299920 
      # public see: http://stackoverflow.com/a/3343849/299920
      # Another useful: http://stackoverflow.com/a/29117904/299920

    APP.aws.S3.copyObject copy_params, (err, data) =>
      if err?
        @logger.error "Failed to set cache on file"
        console.error err

      return

    Meteor.users.update Meteor.userId(),
      $set:
        "profile.profile_pic": url
        "_profile_pic_metadata": filepicker_blob

    return

  findOnePublicBasicUserInfo: (user_id, options, requesting_user) ->
    # requesting_user can be undefined
    return @fetchPublicBasicUsersInfo([user_id], options, requesting_user)[0]

  fetchPublicBasicUsersInfo: (users_ids, options, requesting_user) ->
    # requesting_user can be undefined
    return _.map @_getPublicBasicUserInfoCursor(users_ids, options).fetch(), (data) => @_publicBasicUserInfoCursorDataOutputTransformer(data, requesting_user)

  _getPublicBasicUserInfoCursor: (users_ids, options) ->
    # Returns the public info of the specified users_ids

    # DO NOT USE THIS METHOD WITHOUT READING THE MESSAGE BELOW

    # IMPORTANT!!!
    # Using this cursor without passing its output through
    # @_publicBasicUserInfoCursorDataOutputTransformer is a serious security breach
    # You *Must* pass all docs returned by the cursor through 
    # @_publicBasicUserInfoCursorDataOutputTransformer()
    # IMPORTANT!!!

    # DO NOT USE THIS METHOD WITHOUT READING THE MESSAGE ABOVE

    # Note, since cursor Transforms are not applied for the callbacks of observeChanges
    # or to cursors returned from publish functions - we don't rely on them here.

    # Allowed options:
    #
    #   additional_fields: {} # fields to pick in addition to the defaults Mongo format (only 'x: 1' is supported!)

    if _.isString users_ids
      users_ids = [users_ids]

    check users_ids, [String]

    fields =
      _id: 1

      emails: 1

      "profile.first_name": 1
      "profile.last_name": 1
      "profile.profile_pic": 1
      "profile.avatar_fg": 1
      "profile.avatar_bg": 1

      "services.password.reset.reason": 1
      "invited_by": 1
      "is_proxy": 1
      "users_allowed_to_edit_pre_enrollment": 1

      "site_admin.is_site_admin": 1

    if options?.additional_fields?
      _.extend fields, options.additional_fields
    
    return Meteor.users.find({_id: {$in: users_ids}}, {fields: fields})

  _basicUserInfoPublicationHandlerOptionsSchema: new SimpleSchema
    users_ids:
      type: [String]
    "public_basic_user_info_cursor_options.additional_fields":
      type: Object

      blackbox: true

      custom: ->
        if @isSet
          for field, val of @value
            if not _.isString field
              console.error "all fields must be strings"

              return "notAllowed"

            if val != 1
              console.error "Only inclusive (val == 1) fields are permitted"

              return "notAllowed"

        return        

      optional: true
  _basicUserInfoPublicationHandlerPubConfSchema: new SimpleSchema
    target_collection:
      type: String

      defaultValue: "users"
  basicUserInfoPublicationHandler: (publish_this, options, pub_conf) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_basicUserInfoPublicationHandlerOptionsSchema,
        options or {},
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    if not options.public_basic_user_info_cursor_options?
      options.public_basic_user_info_cursor_options = {}

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_basicUserInfoPublicationHandlerPubConfSchema,
        pub_conf or {},
        {self: @, throw_on_error: true}
      )
    pub_conf = cleaned_val

    users_tracker = @_getPublicBasicUserInfoCursor(options.users_ids, options.public_basic_user_info_cursor_options).observeChanges
      added: (id, data) =>
        @_publicBasicUserInfoCursorDataOutputTransformer(data, publish_this.userId)

        publish_this.added pub_conf.target_collection, id, data

        return

      changed: (id, data) =>
        @_publicBasicUserInfoCursorDataOutputTransformer(data, publish_this.userId)

        publish_this.changed pub_conf.target_collection, id, data

        return

      removed: (id) =>
        publish_this.removed pub_conf.target_collection, id

        return

    publish_this.onStop ->
      users_tracker.stop()

      return

    publish_this.ready() # we assume everything is synchronous

    return

  _publicBasicUserInfoCursorDataOutputTransformer: (data, requesting_user) ->
    # @_publicBasicUserInfoCursorDataOutputTransformer() and its derived transformations methods
    # below, doesn't assume that data is a full data object that contains all the fields
    # requested by the @_getPublicBasicUserInfoCursor()
    #
    # (partial data object might receive from observeChanges) .
    #
    # Each derived transformation, begins from checking whether the data it uses
    # for the transformation exists in the data object, and perform the transformation
    # only if it does - keeps the data object untouched otherwise.

    @_allEmailsVerifiedTransform(data, requesting_user)
    @_enrolledFlagTransform(data, requesting_user)

    return data

  _allEmailsVerifiedTransform: (data, requesting_user) ->
    if data.is_proxy is true
      data.all_emails_verified = true

      return
    
    if not (emails = data.emails)?
      return
    
    for email in emails
      if not email.verified
        return data.all_emails_verified = false

    data.all_emails_verified = true

    return

  _enrolledFlagTransform: (data, requesting_user) ->
    if (password = data.services?.password)?
      delete data.services.password # _enrolledFlagTransform is the only transformation that uses the services.password sub-document.

    if data.is_proxy is true
      data.enrolled_member = true

      return

    if not password?
      if data.all_emails_verified isnt true # If data.all_emails_verified is true, it is obvious the user completed enrollment (using the oauth flow), even if he doesn't have data.services?.password
        # Remove the invited_by field that is published only in specific cases where
        # the user isn't enrolled, see below.
        delete data.invited_by
        delete data.users_allowed_to_edit_pre_enrollment

        return

    if _.isEmpty data.services
      delete data.services

    if data.invited_by != requesting_user
      # We don't want to leak invited_by info to those that doesn't need it.
      delete data.invited_by

    if _.isArray(data.users_allowed_to_edit_pre_enrollment) and requesting_user not in data.users_allowed_to_edit_pre_enrollment
      delete data.users_allowed_to_edit_pre_enrollment

    if password?.reset?.reason == "enroll"
      data.enrolled_member = false
    else
      data.enrolled_member = true

    return

  _editPreEnrollmentUserDataSchema:
    new SimpleSchema([
      JustdoAccounts.user_profile_schema.pick(["first_name", "last_name"]),
      new SimpleSchema {
        email: {
          label: "Email"
          type: String
          regEx: JustdoHelpers.common_regexps.email
        }
      }
    ])
  editPreEnrollmentUserData: (user_id, data, requesting_user) ->
    user = @getUserById(user_id)

    if user.services?.password?.reset?.reason != "enroll"
      throw @_error "permission-denied", "Details can be edited, only for unregistered members, member #{first_name} #{last_name} registered already."

    users_allowed_to_edit_pre_enrollment = (user.users_allowed_to_edit_pre_enrollment or []).slice() # slice to avoid edit by reference
    if _.isString(user.invited_by)
      users_allowed_to_edit_pre_enrollment.push user.invited_by

    if not requesting_user? or requesting_user not in users_allowed_to_edit_pre_enrollment
      throw @_error "permission-denied", "Only the user that invited a member, can edit its details."

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_editPreEnrollmentUserDataSchema,
        data,
        {self: @, throw_on_error: true}
      )
    data = cleaned_val

    email_changed = false
    update = {$set: {}}
    for prop, val of data
      if prop in ["first_name", "last_name"]
        if user.profile[prop] != data[prop]
          update["$set"]["profile.#{prop}"] = data[prop]
      else if prop == "email"
        if user.emails[0].address != data.email
          email_changed = true

          update["$set"]["services.password.reset.email"] = data[prop]
          update["$set"]["services.password.reset.token"] = Random.secret() # Update token, so the receiver of the mistaken email, won't be able to enroll
          update["$set"]["emails.0.address"] = data[prop]

          if Accounts.findUserByEmail(data.email)?
            throw @_error "user-already-exists", "User with email #{data.email} is already registered."
      else
        console.warn "JustdoAccounts.editPreEnrollmentUserData: unhandled prop: #{prop}"

    result = {email_changed}

    if _.isEmpty update.$set
      # Nothing to do

      return result

    Meteor.users.update(user_id, update)

    return result

  changeAccountEmail: (email, password, user_id) ->
    @requireLogin(user_id)

    if not email? or not JustdoHelpers.common_regexps.email.test(email)
      throw @_error("invalid-email")

    if not (user_doc = Meteor.users.findOne(user_id))?
      throw @_error("unknown-user")

    password_check = Accounts._checkPassword(user_doc, password)

    if password_check.error?
      throw password_check.error

    if Accounts.findUserByEmail(email)?
      throw @_error "user-already-exists", "User with email #{email} is already registered."

    update =
      $set:
        "emails.0.address": email
        "emails.0.verified": false

      $unset:
        "services.google": 1

    Meteor.users.update(user_id, update)

    @sendVerificationEmail(user_id)

    return

  deactivateUsers: (users_ids) ->
    if _.isString users_ids
      users_ids = [users_ids]

    check users_ids, [String]

    query =
      _id:
        $in: users_ids

    update =
      $set:
        deactivated: true

    Meteor.users.update(query, update, {multi: true})

    Accounts.logoutAllClients users_ids

    return

  reactivateUsers: (users_ids) ->
    if _.isString users_ids
      users_ids = [users_ids]

    check users_ids, [String]

    query =
      _id:
        $in: users_ids

    update =
      $unset:
        deactivated: ""

    Meteor.users.update(query, update, {multi: true})

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"
