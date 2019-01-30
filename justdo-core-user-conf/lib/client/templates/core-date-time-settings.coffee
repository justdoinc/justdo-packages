getUserSchemaForField = (field) ->
  return JustdoHelpers.getCollectionSchemaForField(Meteor.users, field)

Template.core_user_conf_core_time_settings.helpers
  label: ->
    return getUserSchemaForField("profile.date_format").label

  user_date_format: ->
    if not (user_date_format = Meteor.user().profile?.date_format)?
      return getUserSchemaForField("profile.date_format").defaultValue

    return user_date_format

  allowed_date_formats: ->
    if not (allowed_date_formats = getUserSchemaForField("profile.date_format")?.allowedValues)?
      return ["YYYY-MM-DD"]

    return allowed_date_formats

Template.core_user_conf_core_time_settings.events
  "change .date-format-date-time-setting": (e) ->
    Meteor.users.update(Meteor.userId(), {$set: {"profile.date_format": $(e.target).val()}})

    return