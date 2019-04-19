_.extend JustdoAccounts.prototype,
  _getAvatarUploadPath: (user_id) ->
    return "/accounts-avatars/#{user_id}/"

  _testAvatarUploadPath: (path, user_id) ->
    return new RegExp("\\/accounts-avatars\\/#{user_id}\\/[^\\\\]+$").test(path)

  splitting_signs: ["+", " ", ".", "#", "-"]
  passwordStrengthValidator: (password, user_inputs) ->
    # If there is no issue with the password, returns undefined.
    #
    # If there is an issue, returns an object with:
    #
    # {
    #   code: "" # dash separated error code
    #   reason: "" # Suggested human readable error message to display
    # }
    #
    # Returns an object with string with a human readable password issue, or undefined if there
    # is no issue
    #
    # user_inputs is an array of user inputs that we need to ensure aren't
    # similar to the password, can be undefined or empty

    if not password? or not _.isString(password) or password.length == 0
      return {code: "empty", reason: "Please set a password"}

    minimum_length = 8
    minimum_length = Math.max(@options.password_strength_minimum_chars or minimum_length, minimum_length)

    if password.length < minimum_length
      return {code: "too-short", reason: "Password must consist of at least #{minimum_length} characters"}

    if not /([\d])/i.test(password)
      return {code: "missing-number", reason: "Password must have at least one number"}

    if not /([^\d\w\s])/i.test(password)
      return {code: "missing-special-sign", reason: "Password must have at least one special character"}

    if not /[a-z]/.test(password)
      return {code: "atleast-one-lowercase", reason: "Password must have at least one lower case English letter"}

    if not /[A-Z]/.test(password)
      return {code: "atleast-one-uppercase", reason: "Password must have at least one capital English letter"}

    # From here on, we are testing similarity to user_inputs
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
        for splitting_sign in @splitting_signs
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
        return {code: "too-similar", reason: "Password is too similar to your other inputs"}

    return undefined
