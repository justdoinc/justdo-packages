_.extend JustdoResourcesAvailability.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @setupRouter()

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
