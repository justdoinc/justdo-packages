_.extend JustdoAccounts.prototype,
  _setupDbMigrations: ->
    APP.executeAfterAppLibCode -> 
      if not APP.justdo_db_migrations?
        return
        
      migration_name = "remove-proxy-avatar-border-for-non-proxy-users"

      APP.justdo_db_migrations.registerMigrationScript migration_name, JustdoDbMigrations.commonBatchedMigration
        delay_between_batches: 1000 * 10
        batch_size: 1000
        collection: Meteor.users
        mark_as_completed_upon_batches_exhaustion: true
        queryGenerator: ->
          # Look for avatars that contain the proxy border pattern (dashed stroke)
          # This ensures we only process users who actually have proxy borders to remove.
          #
          # All of the cached avatars SVGs been generated with getInitialsSvg where all the content
          # that comes before the `stroke-dasharray: 2 5` is exactly of the same length.
          proxy_border_pattern = "stroke-dasharray: 2 5"
          proxy_border_pattern = Buffer.from(proxy_border_pattern).toString("base64")
          proxy_border_pattern = new RegExp(JustdoHelpers.escapeRegExp(proxy_border_pattern))
          query = 
            # Querying with `proxy_created_at` is more proper, but this field is created 1 year after the `is_proxy` flag was introduced.
            # As such, using `proxy_created_at` does not guarantee that we fetch all the users who were proxies. 
            is_proxy: 
              $ne: true
            "profile.profile_pic": 
              $regex: proxy_border_pattern
          query_options = 
            fields:
              profile: 1
              emails: 1
          return {query, query_options}
        static_query: true
        batchProcessor: (users_cursor) ->
          num_processed = 0
          users_cursor.forEach (user) ->
            @logger.info "Found non-proxy user with proxy border: #{user._id}, removing proxy border."
            num_processed += 1
            existing_user_avatar_details = JustdoAvatar.getCachedInitialAvatarDetails(user)
            if existing_user_avatar_details.is_base64_svg_avatar
              modifier = {}
              # `applyCachedAvatarUpdate` will return a new modifier object with the updated avatar and it's colors
              # It will reuse the existing avatar colors when generating the new avatar
              JustdoAvatar.applyCachedAvatarUpdate modifier, user
              regenerated_avatar = modifier.$set["profile.profile_pic"]
              # If the regenerated avatar is different from the existing avatar, update the user's avatar
              if regenerated_avatar isnt user.profile.profile_pic
                Meteor.users.update user._id, modifier
              else
                @logger.warn "Regenerated avatar for user #{user._id} is the same as the existing avatar - this should not happen."
            return
          return num_processed
      return
    
    return