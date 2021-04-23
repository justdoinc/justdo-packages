getUserSchemaForField = (field) ->
  return JustdoHelpers.getCollectionSchemaForField(Meteor.users, field)

Template.core_user_conf_core_profile_settings.helpers
  first_name_label: -> getUserSchemaForField("profile.first_name").label

  last_name_label: -> getUserSchemaForField("profile.last_name").label

  logged_user_first_name_last_name: -> Meteor.user({fields: {"profile.first_name": 1, "profile.last_name": 1}})

updateFirstName = (new_first_name) ->
  Meteor.users.update Meteor.userId(),
    $set: "profile.first_name": new_first_name

updateLastName = (new_last_name) ->
  Meteor.users.update Meteor.userId(),
    $set: "profile.last_name": new_last_name

updateInitialsAvatarIfNecessary = (old_profile, new_profile) ->
  APP.accounts.updateCachedInitialsAvatar(old_profile, new_profile)

Template.core_user_conf_core_profile_settings.events
  "change .first-name-core-setting": (e) ->
    updateFirstName($(e.target).val())

    return

  "change .last-name-core-setting": (e) ->
    updateLastName($(e.target).val())

    return

  "keyup .first-name-core-setting": (e) ->
    # fakeMongoUpdate doesn't trigger collections hooks, so we have
    # to update the initials ourself.

    # Wait 1 second before updating, to avoid quick typing overrided
    # by the reactive process that sets the input to the new value
    JustdoHelpers.delayedCallOfLastRequest
      manager_id: "first-name-core-setting"
      timeout: 500
      func: ->
        new_first_name = $(e.target).val()

        old_profile = Meteor.user()

        JustdoHelpers.fakeMongoUpdate Meteor.users, Meteor.userId(),
          $set: "profile.first_name": new_first_name

        new_profile = Meteor.user()

        # If we need to update initials avatar for the user, we must first
        # update the server about the current user display name, otherwise
        # when the server will send us back the updated profile subdocument
        # it'll include the previous name and will override the changed name
        if APP.accounts.isInitialsAvatarsUpdateNecessary(old_profile.profile, new_profile.profile)
          updateFirstName(new_first_name)

          APP.accounts.updateCachedInitialsAvatar()

        return

    return

  "keyup .last-name-core-setting": (e) ->
    # fakeMongoUpdate doesn't trigger collections hooks, so we have
    # to update the initials ourself.

    # Wait 1 second before updating, to avoid quick typing overrided
    # by the reactive process that sets the input to the new value
    JustdoHelpers.delayedCallOfLastRequest
      manager_id: "first-name-core-setting"
      timeout: 500
      func: ->
        new_last_name = $(e.target).val()

        old_profile = Meteor.user()

        JustdoHelpers.fakeMongoUpdate Meteor.users, Meteor.userId(),
          $set: "profile.last_name": new_last_name

        new_profile = Meteor.user()

        # If we need to update initials avatar for the user, we must first
        # update the server about the current user display name, otherwise
        # when the server will send us back the updated profile subdocument
        # it'll include the previous name and will override the changed name
        if APP.accounts.isInitialsAvatarsUpdateNecessary(old_profile.profile, new_profile.profile)
          updateLastName(new_last_name)

          APP.accounts.updateCachedInitialsAvatar()

        return

    return