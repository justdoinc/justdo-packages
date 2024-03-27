APP.getEnv (env) ->
  minimum_password_length = 8
  password_strength_minimum_chars =
    Math.max(parseInt(env.PASSWORD_STRENGTH_MINIMUM_CHARS, 10) or minimum_password_length, minimum_password_length)

  APP.accounts = new JustdoAccounts
    password_strength_minimum_chars: password_strength_minimum_chars
    new_accounts_custom_fields:
      "justdo_projects.post_reg_init": false
      "justdo_projects.daily_email_projects_array": []

  APP.emit "app-accounts-ready"

  return