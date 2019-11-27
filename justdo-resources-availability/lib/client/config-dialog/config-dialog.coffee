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
days_of_week = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

Template.justdo_resources_availability_config_dialog.onCreated ->
  data = Template.currentData()
  data.has_issues = new Set()
  #if we don't have weekdays, let's set defaults
  if not data.weekdays
    data.weekdays = {}
    for i in [0..6]
      data.weekdays["#{i}"] =
        from: "08:00"
        to: "16:00"
        holiday: true
  if not data.holidays
    data.holidays = new Set()

  return

Template.justdo_resources_availability_config_dialog.helpers
  week_days: -> return days_of_week

  holidaysFormatError: ->
    if holidays_string_is_valid.get()
      return
    return "holidays_format_error"

  holidaysList: ->
    ret = ""
    Template.currentData().holidays.forEach (day)->
      ret += day + ", "

    return ret.slice 0, -2

Template.justdo_resources_availability_config_dialog.events
  "keyup/change/paste/blur .availability_config_dialog_holidays": (e, tpl) ->
    has_issues = Template.currentData().has_issues
#    data_holidays = Template.currentData().holidays
    Meteor.defer =>
      val = $(e.target).val().trim()
      val = val.replace(/\n/g, ",");
      val = val.replace(/,,/g, ",");
      all_dates = val.split(",")

      for date in all_dates
        date = date.trim()
        if date!="" and moment(date , "YYYY-MM-DD", true).isValid() == false
          holidays_string_is_valid.set(false)
          has_issues.add "issue_with_holidays"
          return
      holidays_string_is_valid.set(true)
      has_issues.delete "issue_with_holidays"
      return
    return


###
  data: day of week like "Sunday"...
###
Template.justdo_resources_availability_config_dialog_workday.onCreated ->
  @is_holiday = new ReactiveVar()
  if (day = Template.parentData().weekdays["#{days_of_week.indexOf(Template.instance().data)}"])
    @is_holiday.set(day.holiday)
  else
    @is_holiday.set(true)


  @input_is_okay = new ReactiveVar(true)

  @checkData = ->
    to_time = Template.parentData().weekdays["#{days_of_week.indexOf(Template.instance().data)}"]?.to
    from_time = Template.parentData().weekdays["#{days_of_week.indexOf(Template.instance().data)}"]?.from
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
    if ( r = Template.parentData().weekdays["#{days_of_week.indexOf(Template.instance().data)}"]?.from )
      return r
    return "08:00"

  toTime: ->
    if ( r = Template.parentData().weekdays["#{days_of_week.indexOf(Template.instance().data)}"]?.to )
      return r
    return "16:00"

Template.justdo_resources_availability_config_dialog_workday.events
  "change .form-check-input": (e, tpl)->

    parent_data = Template.parentData()
    Meteor._ensure parent_data, "weekdays", "#{days_of_week.indexOf(Template.instance().data)}"
    parent_data_day = parent_data.weekdays["#{days_of_week.indexOf(Template.instance().data)}"]
    if e.target.checked
      parent_data_day.holiday = false
      Template.instance().is_holiday.set(false)
    else
      parent_data_day.holiday = true
      Template.instance().is_holiday.set(true)
    return

  "change .from_time": (e, tpl)->
    Template.parentData().weekdays["#{days_of_week.indexOf(Template.instance().data)}"].from = e.target.value
    Template.instance().checkData()
    return

  "change .to_time": (e, tpl)->

    Template.parentData().weekdays["#{days_of_week.indexOf(Template.instance().data)}"].to = e.target.value
    Template.instance().checkData()
    return




