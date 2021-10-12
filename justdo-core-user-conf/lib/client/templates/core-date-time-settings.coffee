getUserSchemaForField = (field) ->
  return JustdoHelpers.getCollectionSchemaForField(Meteor.users, field)

Template.core_user_conf_core_time_settings.helpers
  #
  # Date format
  #
  date_format_label: ->
    return getUserSchemaForField("profile.date_format").label

  user_date_format: ->
    if not (user_date_format = Meteor.user({fields: {"profile.date_format": 1}}).profile?.date_format)?
      return getUserSchemaForField("profile.date_format").defaultValue

    return user_date_format

  allowed_date_formats: JustdoHelpers.getAllowedDateFormatsWithExample

  #
  # Time format
  #
  use_am_pm_format_label: ->
    return getUserSchemaForField("profile.use_am_pm").label

  use_am_pm: ->
    if not (use_am_pm = Meteor.user({fields: {"profile.use_am_pm": 1}}).profile?.use_am_pm)?
      return getUserSchemaForField("profile.use_am_pm").defaultValue

    return use_am_pm

  #
  # First day of week
  #
  first_day_of_week_label: ->
    return getUserSchemaForField("profile.first_day_of_week").label

  first_day_of_week: ->
    if not (first_day_of_week = Meteor.user({fields: {"profile.first_day_of_week": 1}}).profile?.first_day_of_week)?
      return getUserSchemaForField("profile.first_day_of_week").defaultValue

    return first_day_of_week

  allowed_first_day_of_week_inputs: [
    {id: 0, name: "Sunday"},
    {id: 1, name: "Monday"},
    {id: 2, name: "Tuesday"},
    {id: 3, name: "Wednesday"},
    {id: 4, name: "Thursday"},
    {id: 5, name: "Friday"},
    {id: 6, name: "Saturday"}
  ]

Template.core_user_conf_core_time_settings.events
  "change .date-format-date-time-setting": (e) ->
    Meteor.users.update(Meteor.userId(), {$set: {"profile.date_format": $(e.target).val()}})

    return

  "change .use-am-pm-date-time-setting": (e) ->
    new_value = null

    if $(e.target).val() == "12"
      new_value = true
    else if $(e.target).val() == "24"
      new_value = false

    Meteor.users.update(Meteor.userId(), {$set: {"profile.use_am_pm": new_value}})

    return

  "change .first-week-day-date-time-setting": (e) ->
    Meteor.users.update(Meteor.userId(), {$set: {"profile.first_day_of_week": parseInt($(e.target).val(), 10)}})

    return

