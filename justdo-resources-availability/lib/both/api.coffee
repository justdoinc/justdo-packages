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
    if (resource_conf = JD.activeJustdo(
      _id: 1,
      "#{custom_feature_id}": 1
    )?["#{custom_feature_id}"])?
      if (resources_obj = resource_conf[project_id])?
        # next - add the justdo level workdays (where available)
        for holiday in resources_obj.holidays
          justdo_workdays.holidays.push holiday
        for day, data of resources_obj.working_days
          #overrite only when we have explicit info
          if data.holiday?
            justdo_workdays.days[day].holiday = data.holiday
          if data.from?
            justdo_workdays.days[day].from = data.from
          if data.to?
            justdo_workdays.days[day].to = data.to      
      # next - add the user levbel workdays (where available)
      if user_id? and (resources_obj = resource_conf["#{project_id}:#{user_id}"])?
          for holiday in resources_obj.holidays
            justdo_workdays.holidays.push holiday
          for day, data of resources_obj.working_days
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


  justdoAvailabilityBetweenDates: (from_date, to_date, project_id_or_doc, user_id) ->
    return @userAvailabilityBetweenDates(from_date, to_date, project_id_or_doc, user_id, {
      always_use_justdo_level_data: true
    })

  # Given a project_id and a user id, the function will return the number of days and total hours available
  # between the dates. dates are in the format of YYYY-MM-DD

  userAvailabilityBetweenDates: (from_date, to_date, project_id_or_doc, user_id, options)->
    check from_date, Match.Maybe String
    check to_date, Match.Maybe String
    check project_id_or_doc, Match.OneOf String, Object
    check user_id, String
    
    options = _.extend {
      always_use_justdo_level_data: false
      include_start_date: true
      include_end_date: true
    }, options

    if not from_date? or not to_date?
      return {
        working_days: null
        available_hours: null
      }

    {justdo_level_data, user_level_data} = @_getAvailabilityData project_id_or_doc, user_id

    if options.always_use_justdo_level_data
      user_level_data = null

    ret =
      working_days: 0
      available_hours: 0
    
    if not _.isEmpty user_level_data?.working_days
      use_data = user_level_data
    else
      use_data = justdo_level_data
    
    start_date = moment.utc(from_date)
    end_date = moment.utc(to_date)

    if end_date < start_date
      reverse = true

    nextStartDate = ->
      if reverse
        start_date.add(-1, 'days')
      else
        start_date.add(1, 'days')
      return
    
    prevEndDate = ->
      if reverse
        end_date.add(1, 'days')
      else
        end_date.add(-1, 'days')
      return

    loopCondition = ->
      if reverse
        return start_date >= end_date
      else
        return start_date <= end_date
        
    if not options.include_start_date
      nextStartDate()
    
    if not options.include_end_date
      prevEndDate()
    
    while loopCondition()
      date = start_date.format("YYYY-MM-DD")
      is_holiday = false
      if user_level_data?.holidays? and (date in user_level_data.holidays) or \
        justdo_level_data?.holidays and (date in justdo_level_data.holidays) or \
        use_data?.working_days?[start_date.day()]?.holiday
        is_holiday = true

      if not is_holiday
        ret.working_days +=1
        ret.available_hours += @_calculateUserDayAvailability justdo_level_data, user_level_data, start_date.day()

      nextStartDate()

    if reverse
      ret.working_days = -ret.working_days
      ret.available_hours = -ret.available_hours

    return ret
  
  getWorkdaysPerWeekOfJustdo: (justdo_id) ->
    avail_data = @_getAvailabilityData justdo_id, Meteor.userId()
    if not (working_days = avail_data?.justdo_level_data?.working_days)?
      return null
    
    working_days_per_week = 0
    for day, day_obj of working_days
      if day_obj.holiday == false
        working_days_per_week += 1
    
    return working_days_per_week
        
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
  
  startToFinishForUser: (project_id_or_doc, user_id, start_date, amount, type)->
    check project_id_or_doc, Match.OneOf String, Object
    check user_id, String
    check start_date, Match.Maybe String
    check amount, Match.Maybe Number
    check type, String
    if type not in ["hours", "days"]
      throw "incompatible-type"

    if not start_date? or not amount?
      return null
      
    {justdo_level_data, user_level_data} = @_getAvailabilityData project_id_or_doc, user_id

    start_date = moment.utc(start_date)
    max_count = 10000
    
    reverse = amount < 0
    amount = Math.abs(amount)
      
    while true
      date = start_date.format("YYYY-MM-DD")
      is_holiday = false

      if not _.isEmpty user_level_data?.working_days
        use_data = user_level_data
      else
        use_data = justdo_level_data

      if user_level_data?.holidays? and (date in user_level_data.holidays) or \
        justdo_level_data?.holidays and (date in justdo_level_data.holidays) or \
        use_data?.working_days?[start_date.day()]?.holiday
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
        console.log "No working days for this user and justdo"
        return null
    
    return start_date.format("YYYY-MM-DD")
  
  finishToStartForUser: (project_id_or_doc, user_id, start_date, amount, type) ->
    return @startToFinishForUser project_id_or_doc, user_id, start_date, -amount, type

  nextWorkingDayForUser: (project_id_or_doc, user_id, start_date, amount) ->
    check project_id_or_doc, Match.OneOf String, Object
    check user_id, String
    check start_date, String
    check amount, Number

    {justdo_level_data, user_level_data} = @_getAvailabilityData project_id_or_doc, user_id

    start_date = moment.utc(start_date)
    max_count = 10000
    
    reverse = amount < 0
    amount = Math.abs(amount)
        
    while amount > 0
      start_date.add((if reverse then -1 else 1), 'days')

      date = start_date.format("YYYY-MM-DD")
      is_holiday = false

      if not _.isEmpty user_level_data?.working_days
        use_data = user_level_data
      else
        use_data = justdo_level_data

      if user_level_data?.holidays? and (date in user_level_data.holidays) or \
        justdo_level_data?.holidays and (date in justdo_level_data.holidays) or \
        use_data?.working_days?[start_date.day()]?.holiday
        is_holiday = true

      if not is_holiday
        amount -= 1

      #should never happen, but just in case...
      max_count -= 1
      if max_count == 0
        console.log "No working days for this user and justdo"
        return null
    
    return start_date.format("YYYY-MM-DD")
    
  getUserAvgWorkHoursPerDay: (user_id, project_id_or_doc) ->
    {justdo_level_data, user_level_data} = @_getAvailabilityData project_id_or_doc, user_id
    
    if not _.isEmpty user_level_data?.working_days
      use_data = user_level_data
    else
      use_data = justdo_level_data

    total_hours = 0
    days = 0
    for day_of_week, obj of use_data.working_days
      total_hours += @_calculateUserDayAvailability justdo_level_data, user_level_data, day_of_week
      days += 1

    return total_hours / days

  userWorkdays: (user_id, start_date, project_id_or_doc) ->
    self = @
    return {
      [Symbol.iterator]: () ->
        {justdo_level_data, user_level_data} = self._getAvailabilityData project_id_or_doc, user_id

        i_date = moment(start_date)

        if not _.isEmpty user_level_data?.working_days
          use_data = user_level_data
        else
          use_data = justdo_level_data

        first = true

        return {
          next: () =>
            if first
              first = false
            else
              i_date.add 1, "days"

            while true
              date = i_date.format("YYYY-MM-DD")
              is_holiday = false

              if user_level_data?.holidays? and (date in user_level_data.holidays) or \
                justdo_level_data?.holidays and (date in justdo_level_data.holidays) or \
                use_data?.working_days?[i_date.day()]?.holiday
                is_holiday = true

              if not is_holiday
                return {
                  value: {
                    date: i_date
                    available_hours: self._calculateUserDayAvailability justdo_level_data, user_level_data, i_date.day()
                  }
                  done: false
                };

              i_date.add 1, "days"
        }
    }

  _getAvailabilityData: (project_id_or_doc, user_id) ->
    if _.isString project_id_or_doc
      project_obj = JD.collections.Projects.findOne
        _id: project_id_or_doc
        members: 
          $elemMatch:
            user_id: user_id
      ,
        fields: @_getAvailabilityData_getRequiredJustdoFields()
          
    else
      project_obj = project_id_or_doc

    if not project_obj?
      return {
        justdo_level_data: @default_workdays
        user_level_data: null
      }

    project_id = project_obj._id

    resources_data = project_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]
    if not (justdo_level_data = resources_data?[project_id])?
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
  
  atLeastOneWorkingDay: (weekdays) ->
    for i, weekday of weekdays
      if weekday.holiday == false
        return true
    
    return false
  
  includesHolidays: (project_id, user_id, start_date, end_date) ->
    if not start_date? or not end_date?
      return false

    {justdo_level_data, user_level_data} = @_getAvailabilityData(project_id, user_id)

    return {
      includes_justdo_holiday: @_includesHoliday(justdo_level_data, start_date, end_date)
      includes_user_holiday: @_includesHoliday(user_level_data, start_date, end_date)
    }
  
  _includesHoliday: (data, start_date, end_date) ->
    if not data?.holidays? or _.isEmpty(start_date) or _.isEmpty(end_date)
      return false
    
    for holiday in data.holidays
      if holiday >= start_date and holiday <= end_date
        return true

    return false