_.extend JustdoAccounts.prototype,
  _setupCollectionsHooks: ->
    # Update cached initials avatar upon changes to first_name/last_name
    Meteor.users.before.update (user_id, doc, fields, modifier, options) =>
      JustdoHelpers.applyMongoModifiers doc, modifier, (e, modified_doc) =>
        if e?
          @logger.debug "initials-avatar-updater-hook-skipped"
          # Many non-critical edge cases can cause this to happen,
          # so we don't use @logger.error.

          return

        old_profile = doc.profile
        modified_profile = modified_doc.profile

        @updateInitialsAvatarIfNecessary(old_profile, modified_profile)

        return

      return

    return