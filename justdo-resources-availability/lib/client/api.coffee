calculateUserDayAvailability = (justdo_level_data, user_level_data, day_of_week)->
  if not (from = user_level_data?.working_days?[day_of_week]?.from)
    from = justdo_level_data?.working_days?[day_of_week]?.from
  if not (to = user_level_data?.working_days?[day_of_week]?.to)
    to = justdo_level_data?.working_days?[day_of_week]?.to
  if from and to and to > from
    from = from.split(":")
    to = to.split(":")
    return (( (parseInt(to[0]) * 60) + (parseInt(to[1])) - parseInt(from[0]) * 60 - parseInt(from[1]) ) / 60)
  return 0




_.extend JustdoResourcesAvailability.prototype,

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

  _immediateInit: ->
    @initDefaultWorkdays()
    return

  _deferredInit: ->
    if @destroyed
      return

    @setupCustomFeatureMaintainer()
    return

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoResourcesAvailability.project_custom_feature_id,
        installer: =>
          return

        destroyer: =>
          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  # The following is used for client-side plugins to register/unregister for the project-resources data in the project document
  subscribers_to_project_data: new Set()
  enableResourceAvailability: (requesting_plugin_id)->
    check requesting_plugin_id, String
    if @subscribers_to_project_data.has requesting_plugin_id
      return
    @subscribers_to_project_data.add requesting_plugin_id
    if @subscribers_to_project_data.size == 1
      @subscription_tracker = Tracker.autorun =>
        @resorce_availability_subscription = Meteor.subscribe "jd-resource-availability", JD.activeJustdo({_id: 1})._id
        return

      JD.registerPlaceholderItem  "#{JustdoResourcesAvailability.project_custom_feature_id}:global-config", {
        domain: "settings-dropdown-bottom"
        listingCondition: () => return JD.active_justdo.isAdmin()
        data:
          template: "justdo_resources_availability_project_config"
          template_data: {}
      }
    return

  disbleResourceAvailability: (requesting_plugin_id)->
    check requesting_plugin_id, String
    @subscribers_to_project_data.delete requesting_plugin_id
    if @subscribers_to_project_data.size == 0
      @resorce_availability_subscription.stop()
      @subscription_tracker.stop()
      JD.unregisterPlaceholderItem "#{JustdoResourcesAvailability.project_custom_feature_id}:global-config"
    return

  # The following will open the resources config dialog.
  # if user_id is provided - then for the user in the current JustDo, else - for the entire JustDo
  displayConfigDialog: (project_id, user_id, task_id)->
    if not project_id
      project_id = JD.activeJustdo({_id: 1})._id

    # load user task specific info
    if task_id?
      #todo: project config
      alert "Not Ready"
      return

    # load user specific info
    else if user_id?
      if!(proj_obj = APP.collections.Projects.findOne(project_id))
        throw "Cant find project id"

      user = Meteor.users.findOne({_id:user_id})
      config_data =
        title: "Workdays for #{JD.activeJustdo().title}: #{user.profile.first_name} #{user.profile.last_name}"
        weekdays: proj_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]?["#{project_id}:#{user_id}"]?.working_days
        holidays: proj_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]?["#{project_id}:#{user_id}"]?.holidays

    #load project specific info
    else
      if!(proj_obj = APP.collections.Projects.findOne(project_id))
        throw "Cant find project id"

      config_data =
        title: "Workdays for #{JD.activeJustdo().title}"
        weekdays: proj_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]?[project_id]?.working_days
        holidays: proj_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]?[project_id]?.holidays

    config_data.config_user_id = user_id

    message_template =
      JustdoHelpers.renderTemplateInNewNode(Template.justdo_resources_availability_config_dialog, config_data)

    dialog_button_label = "Close"
    if JD.active_justdo.isAdmin() or user_id == Meteor.userId()
      dialog_button_label = "Save"


    bootbox.dialog
      title: config_data.title
      message: message_template.node
      animate: true
      className: "bootbox-new-design"

      onEscape: ->
        return true

      buttons:
        save:
          label: dialog_button_label
          className: "btn-primary resources_availability_close_dialog_button"
          callback: ->
            if config_data.has_issues.size > 0
              return false

            all_holidays = $(".availability_config_dialog_holidays")[0].value
            all_holidays = all_holidays.replace(/\n/g, " ")
            all_holidays = all_holidays.replace(/,/g, " ")
            all_holidays = all_holidays.replace(/\s\s+/g, ' ')
            all_holidays = all_holidays.trim()
            all_holidays = all_holidays.split(" ")

            Meteor.call "jdraSaveResourceAvailability", \
                    project_id,{working_days: config_data.weekdays, holidays: all_holidays},\
                    user_id, task_id, (err, ret)->
              return


            return true

    return

  startToFinishForUser: (project_id, user_id, start_date, amount, type)->
    check project_id, String
    check user_id, String
    check start_date, String
    check amount, Number
    check type, String
    if type not in ["hours", "days"]
      throw "incompatible-type"

    if not (project_obj = JD.collections.Projects.findOne({_id: project_id}))
      return

    resources_data = project_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]
    if !(justdo_level_data  = resources_data?[project_id])
      justdo_level_data = @default_workdays
    if user_id
      user_level_data = resources_data?["#{project_id}:#{user_id}"]

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
          amount -= calculateUserDayAvailability justdo_level_data, user_level_data, start_date.day()

      if amount > 0
        start_date.add(1, 'days')
      else
        break

      #should never happen, but just in case...
      max_count -= 1
      if max_count == 0
        throw "infinite-loop"

    return start_date.format("YYYY-MM-DD")

  # Given a project_id and a user id, the function will return the number of days and total hours available
  # between the dates. dates are in the format of YYYY-MM-DD
  userAvailabilityBetweenDates: (from_date, to_date, project_id, user_id, task_id)->
    check from_date, String
    check to_date, String
    check project_id, String
    check user_id, String
    if task_id
      check task_id, String
      alert "not ready"
      return
    if not (project_obj = JD.collections.Projects.findOne({_id: project_id}))
      return

    resources_data = project_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]
    if !(justdo_level_data  = resources_data?[project_id])
      justdo_level_data = @default_workdays
    if user_id
      user_level_data = resources_data?["#{project_id}:#{user_id}"]

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
        ret.available_hours += calculateUserDayAvailability justdo_level_data, user_level_data, start_date.day()

      start_date.add(1,'days')

    return ret

