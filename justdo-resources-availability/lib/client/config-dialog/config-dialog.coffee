###
  justdo_resources_availability_config_dialog data:
    title: String
    weekdays: dictionary in the format of
      0: #day of week, 0=Sunday
        from: "08:00"
        to: "16:00"
        holiday: true/false
      1:...
  holidays: Set of "YYYY-MM-DD" strings
###
holidays_string_is_valid = new ReactiveVar(true)
getDaysOfWeek = ->
  ret = []
  days_of_week_array_en = TAPi18n.__("days_of_week", {}, "en").split("\n")
  days_of_week_array_translated = TAPi18n.__("days_of_week").split("\n")

  for index of days_of_week_array_en
    en_day = days_of_week_array_en[index]
    translated_day = days_of_week_array_translated[index]
    ret.push {en: en_day, translated: translated_day}

  return ret
  
Template.justdo_resources_availability_config_dialog.onCreated ->
  data = Template.currentData()
  data.has_issues = new Set()
  #if we don't have weekdays, let's set defaults
  if not data.weekdays?
    data.weekdays = {}
  for i in [0..6]
    if not data.weekdays["#{i}"]?
      data.weekdays["#{i}"] =
        from: "08:00"
        to: "16:00"
        holiday: true
  if not data.holidays
    data.holidays = new Set()

  return

Template.justdo_resources_availability_config_dialog.helpers
  daysOfWeek: -> return getDaysOfWeek()

  holidaysFormatError: ->
    if holidays_string_is_valid.get()
      return
    return "holidays_format_error"

  holidaysList: ->
    ret = ""
    Template.currentData().holidays.forEach (day) ->
      ret += day + ", "

    return ret.slice 0, -2

  readonly: ->
    if JD.active_justdo.isAdmin() or Template.currentData().config_user_id == Meteor.userId()
      return ""
    return "readonly"


Template.justdo_resources_availability_config_dialog.events
  "keyup/change/paste/blur .availability_config_dialog_holidays": (e, tpl) ->
    has_issues = Template.currentData().has_issues
#    data_holidays = Template.currentData().holidays
    Meteor.defer =>
      if APP.justdo_resources_availability.parseHolidaysString($(e.target).val().trim()) == false
        holidays_string_is_valid.set(false)
        has_issues.add "issue_with_holidays"
      else
        holidays_string_is_valid.set(true)
        has_issues.delete "issue_with_holidays"

      return
    return


###
  data: day of week like {en: "Sunday", translated: "星期天"}
###
Template.justdo_resources_availability_config_dialog_workday.onCreated ->
  @days_of_week = getDaysOfWeek()

  # The index of the day passed to the data of this template in the days_of_week array
  @day_of_week_index = _.findIndex(@days_of_week, (day_obj) => day_obj.en is @data.en)
    
  @getDayOfWeekDataFromParentTemplate = ->
    return Template.parentData().weekdays[@day_of_week_index]
  
  @is_holiday = new ReactiveVar()
  if (day = @getDayOfWeekDataFromParentTemplate())
    @is_holiday.set(day.holiday)
  else
    @is_holiday.set(true)


  @input_is_okay = new ReactiveVar(true)

  @checkData = ->
    to_time = @getDayOfWeekDataFromParentTemplate()?.to
    from_time = @getDayOfWeekDataFromParentTemplate()?.from
    if from_time <= to_time
      Template.instance().input_is_okay.set(true)
      Template.parentData().has_issues.delete Template.currentData()
    else
      Template.instance().input_is_okay.set(false)
      Template.parentData().has_issues.add Template.currentData()
    return

  return #onCreated

Template.justdo_resources_availability_config_dialog_workday.helpers
  isHoliday: ->
    return Template.instance().is_holiday.get()

  checked: ->
    if Template.instance().is_holiday.get()
      return ""
    return "checked"

  timesChecked: ->
    return Template.instance().input_is_okay.get()

  fromTime: ->
    tpl = Template.instance()
    if ( r = tpl.getDayOfWeekDataFromParentTemplate()?.from )
      return r
    return "08:00"

  toTime: ->
    tpl = Template.instance()
    if ( r = tpl.getDayOfWeekDataFromParentTemplate()?.to )
      return r
    return "16:00"

  readonly: ->
    if JD.active_justdo.isAdmin() or Template.parentData().config_user_id == Meteor.userId()
      return ""
    return "readonly"



Template.justdo_resources_availability_config_dialog_workday.events
  "click .form-check-input": (e, tpl) ->
    if JD.active_justdo.isAdmin() or Template.parentData().config_user_id == Meteor.userId()
      return true
    return false

  "change .form-check-input": (e, tpl) ->
    parent_data = Template.parentData()

    Meteor._ensure parent_data, "weekdays", "#{tpl.day_of_week_index}"
    parent_data_day = tpl.getDayOfWeekDataFromParentTemplate()

    if e.target.checked
      parent_data_day.holiday = false
      tpl.is_holiday.set(false)
    else
      parent_data_day.holiday = true
      tpl.is_holiday.set(true)

    return

  "change .from_time": (e, tpl) ->
    tpl.getDayOfWeekDataFromParentTemplate().from = e.target.value
    Template.instance().checkData()
    return

  "change .to_time": (e, tpl) ->

    tpl.getDayOfWeekDataFromParentTemplate().to = e.target.value
    Template.instance().checkData()
    return




