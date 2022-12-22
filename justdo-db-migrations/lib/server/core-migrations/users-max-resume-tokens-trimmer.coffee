MAX_LOGIN_TOKENS = 10

orderTokensAsc = (login_tokens) ->
  # Items are added to resume.loginTokens using $addToSet
  # which Mongo doesn't guarantee specific insertion order for, therefore we have to sort ourself
  # to avoid surprises.

  login_tokens.sort (a, b) => JustdoHelpers.datesMsDiff(a.when, b.when)

  return login_tokens

APP.executeAfterAppLibCode ->
  migration_name = "users-max-resume-tokens-trimmer"
  APP.justdo_db_migrations.registerMigrationScript migration_name, JustdoDbMigrations.perpetualMaintainer
    delay_between_batches: 5000
    batch_size: 1000
    collection: Meteor.users
    updated_at_field: "services.resume.loginTokens.when"
    delayed_updated_at_field: 0
    queryGenerator: ->
      return {}
    exec_interval: 15 * 1000
    checkpoint_record_name: "#{migration_name}-checkpoint"
    custom_fields_to_fetch: {
      "services.resume.loginTokens.when": 1,
      "services.resume.loginTokens.hashedToken": 1
    }
    customCheckpointValGenerator: (doc) ->
      tokens = orderTokensAsc(doc.services.resume.loginTokens)

      return JustdoHelpers.getDateMsOffset(1, tokens[tokens.length - 1].when)
      # In a massive pre-existing db this won't work correctly, since a user with a very old token
      # and a very recent login token, will push the checkpoint to the future, potentially skipping items
      # that weren't included in the batch.
      #
      # But, we don't have such a use-case in reality, and we mostly
      # need this perpetual maintainer for on-going maintanance.
      # Daniel C.
      #
      # getDateMsOffset adds one milisecond to date since the perpetual maintainer is querying by $gte
      # of the last checkpoint, and we want to avoid repeated querying of items
      # we already checked.
    batchProcessorForEach: (doc) ->
      tokens = doc.services.resume.loginTokens
      if tokens.length <= MAX_LOGIN_TOKENS
        return

      tokens = orderTokensAsc(tokens)
      tokens = tokens.slice(-1 * MAX_LOGIN_TOKENS)

      update_query = {$set: {"services.resume.loginTokens": tokens}}

      Meteor.users.direct.update({_id: doc._id}, update_query, {bypassCollection2: true})

      return

  return