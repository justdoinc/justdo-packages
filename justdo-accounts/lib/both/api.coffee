_.extend JustdoAccounts.prototype,
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
        reason: "consist of at least #{minimum_length} characters"
        validate: (password) -> password.length >= minimum_length
      ,
        code: "missing-number"
        reason: "have at least one number"
        validate: (password) -> /([\d])/i.test(password)
      ,
        code: "missing-special-sign"
        reason: "have at least one special character"
        validate: (password) -> /[*@!#$%&\-\_\+\=\[\]\\\|;:'"/?,<.>()^~{}]+/.test(password)
      ,
        code: "atleast-one-lowercase"
        reason: "have at least one lower case English letter"
        validate: (password) -> /[a-z]/.test(password)
      ,
        code: "atleast-one-uppercase"
        reason: "have at least one capital English letter"
        validate: (password) -> /[A-Z]/.test(password)
      ,
        code: "too-similar"
        reason: "not include your name, or parts of your email"
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
