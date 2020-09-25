_.extend JustdoResourcesAvailability.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @setupRouter()
    @initDefaultWorkdays()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(JustdoResourcesAvailability.project_custom_feature_id, project_doc)

  getProjectDocIfPluginInstalled: (project_id) ->
    return @projects_collection.findOne({_id: project_id, "conf.custom_features": JustdoResourcesAvailability.project_custom_feature_id})

  default_workdays:
    working_days: {}
    holidays: []

  initDefaultWorkdays: ->
    for i in [0..6]
      @default_workdays.working_days["#{i}"] =
        from: "08:00"
        to: "16:00"
        holiday: false
    @default_workdays.working_days[0].holiday = true
    @default_workdays.working_days[6].holiday = true
    return

  # This function gets a list of dates, and then returns two sets - workdays and holidays
  # if user_id is not given, the system will return the project-level information
  workdaysAndHolidaysFor: (project_id, dates_list, user_id)->
    check project_id, String
    if user_id
      check user_id, String
    check dates_list, [String]



    # starting with default workdays
    justdo_workdays =
      days:
        0: {from: "08:00", to: "16:00", holiday: true}
        1: {from: "08:00", to: "16:00", holiday: false}
        2: {from: "08:00", to: "16:00", holiday: false}
        3: {from: "08:00", to: "16:00", holiday: false}
        4: {from: "08:00", to: "16:00", holiday: false}
        5: {from: "08:00", to: "16:00", holiday: false}
        6: {from: "08:00", to: "16:00", holiday: true}
      holidays: []

    # next - see if we have a resources object for the project
    custom_feature_id = JustdoResourcesAvailability.project_custom_feature_id
    if (resourcesObj = JD.activeJustdo(
      _id: 1,
      "#{custom_feature_id}": 1
    )?["#{custom_feature_id}"]?[project_id])
      # next - add the justdo level workdays (where available)
      for holiday in resourcesObj.holidays
        justdo_workdays.holidays.push holiday
      for day, data of resourcesObj.working_days
        #overrite only when we have explicit info
        if data.holiday?
          justdo_workdays.days[day].holiday = data.holiday
        if data.from?
          justdo_workdays.days[day].from = data.from
        if data.to?
          justdo_workdays.days[day].to = data.to
      # next - add the user levbel workdays (where available)
      if user_id?
        custom_feature_id = JustdoResourcesAvailability.project_custom_feature_id
        if (resourcesObj = JD.activeJustdo(
          _id: 1
          "#{custom_feature_id}": 1
        )?["#{custom_feature_id}"]?["#{project_id}:#{user_id}"])
          for holiday in resourcesObj.holidays
            justdo_workdays.holidays.push holiday
          for day, data of resourcesObj.working_days
            #overrite only when we have explicit info
            if data.holiday?
              justdo_workdays.days[day].holiday = data.holiday
            if data.from?
              justdo_workdays.days[day].from = data.from
            if data.to?
              justdo_workdays.days[day].to = data.to
    ret =
      workdays: {}
      holidays: new Set()

    for day in dates_list
      if justdo_workdays.holidays.indexOf(day) > -1
        ret.holidays.add day
      else if justdo_workdays.days[moment(day).day()].holiday
        ret.holidays.add day
      else
        ret.workdays[day] = justdo_workdays.days[moment(day).day()]

    return ret

  # Given a project_id and a user id, the function will return the number of days and total hours available
  # between the dates. dates are in the format of YYYY-MM-DD

  userAvailabilityBetweenDates: (from_date, to_date, project_id_or_doc, user_id)->
    check from_date, String
    check to_date, String
    check project_id_or_doc, Match.OneOf String, Object
    check user_id, String

    {justdo_level_data, user_level_data} = @_getAvailabilityData project_id_or_doc, user_id

    start_date = moment.utc(from_date)
    end_date = moment.utc(to_date)
    ret =
      working_days: 0
      available_hours: 0

    while start_date <= end_date
      date = start_date.format("YYYY-MM-DD")
      is_holiday = false
      if user_level_data?.holidays? and (date in user_level_data.holidays) or \
          user_level_data?.working_days?[start_date.day()]?.holiday or \
          justdo_level_data?.holidays and (date in justdo_level_data.holidays) or \
          justdo_level_data?.working_days?[start_date.day()]?.holiday
        is_holiday = true

      if not is_holiday
        ret.working_days +=1
        ret.available_hours += @_calculateUserDayAvailability justdo_level_data, user_level_data, start_date.day()

      start_date.add(1,'days')

    return ret
    
  _calculateUserDayAvailability: (justdo_level_data, user_level_data, day_of_week)->
    if not (from = user_level_data?.working_days?[day_of_week]?.from)
      from = justdo_level_data?.working_days?[day_of_week]?.from
    if not (to = user_level_data?.working_days?[day_of_week]?.to)
      to = justdo_level_data?.working_days?[day_of_week]?.to
    if from and to and to > from
      from = from.split(":")
      to = to.split(":")
      return (( (parseInt(to[0]) * 60) + (parseInt(to[1])) - parseInt(from[0]) * 60 - parseInt(from[1]) ) / 60)
    return 0
  
  startToFinishForUser: (project_id_or_doc, user_id, start_date, amount, type, reverse=false)->
    check project_id_or_doc, Match.OneOf String, Object
    check user_id, String
    check start_date, String
    check amount, Number
    check type, String
    if type not in ["hours", "days"]
      throw "incompatible-type"

    {justdo_level_data, user_level_data} = @_getAvailabilityData project_id_or_doc, user_id

    start_date = moment.utc(start_date)
    max_count = 10000
    while true
      date = start_date.format("YYYY-MM-DD")
      is_holiday = false
      if user_level_data?.holidays? and (date in user_level_data.holidays) or \
        user_level_data?.working_days?[start_date.day()]?.holiday or \
        justdo_level_data?.holidays and (date in justdo_level_data.holidays) or \
        justdo_level_data?.working_days?[start_date.day()]?.holiday
        is_holiday = true

      if not is_holiday
        if type == "days"
          amount -= 1
        else if type == "hours"
          amount -= @_calculateUserDayAvailability justdo_level_data, user_level_data, start_date.day()

      if amount > 0
        start_date.add((if reverse then -1 else 1), 'days')
      else
        break

      #should never happen, but just in case...
      max_count -= 1
      if max_count == 0
        throw "infinite-loop"

    return start_date.format("YYYY-MM-DD")
  
  finishToStartForUser: (project_id_or_doc, user_id, start_date, amount, type) ->
    return @startToFinishForUser project_id_or_doc, user_id, start_date, amount, type, true

  _getAvailabilityData: (project_id_or_doc, user_id) ->
    if _.isString project_id_or_doc
      project_id = project_id_or_doc
      project_obj = JD.collections.Projects.findOne
        _id: project_id
        members: 
          $elemMatch:
            user_id: user_id
      ,
        fields: @_getAvailabilityData_getRequiredJustdoFields()
          
    else
      project_obj = project_id_or_doc
      
    if not project_obj?
      return

    resources_data = project_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]
    if !(justdo_level_data  = resources_data?[project_id])
      justdo_level_data = @default_workdays
    
    user_level_data = resources_data?["#{project_id}:#{user_id}"]

    return {
      justdo_level_data: justdo_level_data
      user_level_data: user_level_data
    }
  
  _getAvailabilityData_getRequiredJustdoFields: ->
    return {
      "#{JustdoResourcesAvailability.project_custom_feature_id}": 1
    }
    