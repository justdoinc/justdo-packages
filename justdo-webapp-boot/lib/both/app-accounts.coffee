APP.getEnv (env) ->
  minimum_password_length = 8
  password_strength_minimum_chars =
    Math.max(parseInt(env.PASSWORD_STRENGTH_MINIMUM_CHARS, 10) or minimum_password_length, minimum_password_length)

  APP.accounts = new JustdoAccounts
    password_strength_minimum_chars: password_strength_minimum_chars
    new_accounts_custom_fields:
      "justdo_projects.post_reg_init": false
      "justdo_projects.daily_email_projects_array": []

  # The decision to edit the justdo_projects fields here and not in the justdo-projects packages
  # is because the justdo-projects package is not loaded in the landing app, and we want to avoid
  # having to load it just for this. 
  APP.accounts.on "before-create-user-extra-fields-update", (extra_fields, options) ->
    if not _.isEmpty(first_jd = options.first_jd)
      extra_fields["justdo_projects.first_jd"] = first_jd
      
    return
    
  APP.emit "app-accounts-ready"

  return