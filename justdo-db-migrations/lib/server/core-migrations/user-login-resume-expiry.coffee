user_login_resume_token_ttl_ms = process.env.USER_LOGIN_RESUME_TOKEN_TTL_MS

if user_login_resume_token_ttl_ms?
  if not _.isString(user_login_resume_token_ttl_ms)
    throw new Error("Invalid value to env var USER_LOGIN_RESUME_TOKEN_TTL_MS")

  user_login_resume_token_ttl_ms = user_login_resume_token_ttl_ms.trim()

  if user_login_resume_token_ttl_ms == "0" or _.isEmpty(user_login_resume_token_ttl_ms)
    user_login_resume_token_ttl_ms = undefined
  else
    user_login_resume_token_ttl_ms = parseInt(user_login_resume_token_ttl_ms, 10)

    if _.isNaN(user_login_resume_token_ttl_ms) or not _.isNumber(user_login_resume_token_ttl_ms)
      throw new Error("Invalid value provided to env var: USER_LOGIN_RESUME_TOKEN_TTL_MS: #{process.env.USER_LOGIN_RESUME_TOKEN_TTL_MS}")

if user_login_resume_token_ttl_ms?
  console.log "USER_LOGIN_RESUME_TOKEN_TTL_MS=#{user_login_resume_token_ttl_ms} (#{user_login_resume_token_ttl_ms / (1000 * 60 * 60 * 24)} days) Found, setting up expiration procedure"
  Accounts.config({loginExpirationInDays: user_login_resume_token_ttl_ms / (1000 * 60 * 60 * 24)})

#   migration_name = "user-login-resume-expiry"
#   APP.justdo_db_migrations.registerMigrationScript migration_name, JustdoDbMigrations.docExpiryMigration
#     delay_between_batches: 1000
#     batch_size: 2
#     collection: Meteor.users
#     created_at_field: "services.resume.loginTokens.when"
#     ttl: user_login_resume_token_ttl_ms
#     exec_interval: 1 * 60 * 60 * 1000 # 1 hour
#     last_run_record_name: "#{migration_name}-last-run"
#     batchProcessor: (cursor) ->
#       exp_date = new Date()
#       exp_date.setMilliseconds(exp_date.getMilliseconds() - user_login_resume_token_ttl_ms)
#       num_processed = 0
#       cursor.forEach (user) ->
#         Meteor.users.update user._id,
#           $pull:
#             "services.resume.loginTokens":
#               when:
#                 $lte: exp_date
#         num_processed += 1

#       return num_processed