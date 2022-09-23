APP.executeAfterAppLibCode ->
  # See /lib/020-both/035-user-login-resume-token-setup.coffee

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

  return