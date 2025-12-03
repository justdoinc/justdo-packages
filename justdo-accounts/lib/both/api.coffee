_.extend JustdoAccounts.prototype,
  _setupNotifications: ->
    APP.executeAfterAppLibCode ->
      # Important: Since justdo-accounts is a core package that is a depended by many others,
      # we set the dependency of `justdo-emails` to be `unordered` to avoid circular dependencies.
      # As such, we wrap this code in an `APP.executeAfterAppLibCode` to ensure that the code is executed after `justdo-emails` is available.
      JustdoEmails.registerEmailCategory "justdo_accounts",
        label_i18n: "accounts_notifications",
        priority: 300
        notifications: ["email-verification", "password-recovery"]
        notifications_ignoring_user_preference: ["email-verification", "password-recovery"]

      return

    return
  
  _getAvatarUploadPath: (user_id) ->
    return "/accounts-avatars/#{user_id}/"

  _testAvatarUploadPath: (path, user_id) ->
    return new RegExp("\\/accounts-avatars\\/#{user_id}\\/[^\\\\]+$").test(path)

  _setupPasswordRequirements: ->
    APP.getEnv (env) =>
      minimum_length = parseInt env.PASSWORD_STRENGTH_MINIMUM_CHARS
      minimum_length = Math.max(@options.password_strength_minimum_chars or minimum_length, minimum_length)
      splitting_signs = ["+", " ", ".", "#", "-"]

      @_password_requirements = [
        code: "too-short"
        reason: -> TAPi18n.__ "password_requirements_too_short", minimum_length
        validate: (password) -> password.length >= minimum_length
      ,
        code: "missing-number"
        reason: -> TAPi18n.__ "password_requirements_missing_number"
        validate: (password) -> /([\d])/i.test(password)
      ,
        code: "missing-special-sign"
        reason: -> TAPi18n.__ "password_requirements_special_sign"
        validate: (password) -> /[*@!#$%&\-\_\+\=\[\]\\\|;:'"/?,<.>()^~{}]+/.test(password)
      ,
        code: "atleast-one-lowercase"
        reason: -> TAPi18n.__ "password_requirements_atleast_one_lowercase"
        validate: (password) -> /[a-z]/.test(password)
      ,
        code: "atleast-one-uppercase"
        reason: -> TAPi18n.__ "password_requirements_atleast_one_uppercase"
        validate: (password) -> /[A-Z]/.test(password)
      ,
        code: "too-similar"
        reason: -> TAPi18n.__ "password_requirements_too_similar"
        validate: (password, user_inputs) ->
          if password.trim().length == 0
            return false
          
          if _.isString(user_inputs)
            user_inputs = [user_inputs]

          if not user_inputs?
            user_inputs = []

          user_inputs = _.map user_inputs, (x) -> String(x)

          minimum_forbidden_similar_length = 3

          forbidden_strings = {}
          for user_input in user_inputs
            if user_input.length < minimum_forbidden_similar_length
              continue

            parts = []

            parts.push user_input

            if "@" in user_input
              for part in user_input.split("@")
                if part.length >= minimum_forbidden_similar_length
                  parts.push part

            additional_parts = []
            for part in parts
              for splitting_sign in splitting_signs
                if part.indexOf(splitting_sign) >= 0
                  for sub_part in part.split(splitting_sign)
                    if sub_part.length >= minimum_forbidden_similar_length
                      additional_parts.push(sub_part)

            parts = parts.concat(additional_parts)

            for part in parts
              forbidden_strings[part.substr(0, minimum_forbidden_similar_length).toLowerCase()] = true
              forbidden_strings[part.substr(minimum_forbidden_similar_length * -1).toLowerCase()] = true

          lower_cased_password = password.toLowerCase()
          for forbidden_string of forbidden_strings
            if lower_cased_password.indexOf(forbidden_string) >= 0
              return false

          return true
      ]

  getPasswordRequirements: -> @_password_requirements

  getUnconformedPasswordRequirements: (password, user_inputs) ->
    issues = []
    for req in @getPasswordRequirements()
      if req.validate(password, user_inputs) == false
        issues.push req.code
    
    return issues
    
  passwordStrengthValidator: (password, user_inputs) ->
    for req in @getPasswordRequirements()
      if req.validate(password, user_inputs) == false
        return {
          code: req.code
          reason: req.reason
        }

    return undefined

  isUserDeactivated: (user) ->
    # If user is already an object, assume a user object, and avoid request to minimongo
    if _.isString user
      if not (user = Meteor.users.findOne({_id: user}, {fields: {_id: 1, deactivated: 1}}))?
        throw new Meteor.Error("unknown-user")

    if not user? or not _.isObject(user)
      throw new Meteor.Error("invalid-argument")

    return user.deactivated is true

  # Note: This function is overridden when the SDK is initialized.
  # If you changed it, do a full-code-search in the `justdo-devops`.
  isProxyUser: (user) ->
    if _.isString(user)
      user = Meteor.users.findOne user,
        fields:
          is_proxy: 1
    
    return user?.is_proxy is true
  
  _setupOAuthRegistry: ->
    @oauth_providers_registry = {}
    return

  _registerOAuthProviderOptionsSchema: new SimpleSchema
    id:
      type: String
    user_doc_services_field_name:
      type: String
    loginFunction:
      type: Function
      # This is required only on the client side.
      # Check performed inside `registerOAuthProvider`
      optional: true
  registerOAuthProvider: (options) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerOAuthProviderOptionsSchema,
        options,
        {throw_on_error: true}
      )
    options = cleaned_val

    if Meteor.isClient
      check options.loginFunction, Function
    
    if @oauth_providers_registry[options.id]?
      throw @_error "invalid-argument", "OAuth provider id #{options.id} is already registered"

    @oauth_providers_registry[options.id] = options

    return
  
  getSupportedOAuthProviders: ->
    return _.extend {}, @oauth_providers_registry
  
  getSupportedOAuthProviderById: (id) ->
    if not (provider =  @oauth_providers_registry[id])?
      throw @_error "not-supported"

    return _.extend {}, provider
