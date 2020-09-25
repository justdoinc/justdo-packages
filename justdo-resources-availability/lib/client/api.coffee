_.extend JustdoResourcesAvailability.prototype,

  _immediateInit: ->
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

      user = Meteor.users.findOne(user_id)
      config_data =
        title: "Workdays for #{JD.activeJustdo({_id: 1, title: 1}).title}: #{user.profile.first_name} #{user.profile.last_name}"
        weekdays: proj_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]?["#{project_id}:#{user_id}"]?.working_days
        holidays: proj_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]?["#{project_id}:#{user_id}"]?.holidays

    #load project specific info
    else
      if!(proj_obj = APP.collections.Projects.findOne(project_id))
        throw "Cant find project id"

      config_data =
        title: "Workdays for #{JD.activeJustdo({_id: 1, title: 1}).title}"
        weekdays: proj_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]?[project_id]?.working_days or @default_workdays.working_days
        holidays: proj_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]?[project_id]?.holidays or @default_workdays.holidays

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

  justdoLevelDateOffset: (project_id, from_date, offset_days) ->
    check project_id, String
    check from_date, String
    check offset_days, Number

    if offset_days == 0
      return from_date

    date = moment.utc(from_date)
    justdo_level_data = @default_workdays
    if (project_obj = JD.collections.Projects.findOne(project_id))?
      resources_data = project_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]
    if (resources_data?[project_id])?
      justdo_level_data  = resources_data[project_id]

    while offset_days != 0
      is_holiday = false
      if justdo_level_data?.holidays and (date.format("YYYY-MM-DD") in justdo_level_data.holidays) or \
        justdo_level_data?.working_days?[date.day()]?.holiday
        is_holiday = true

      if offset_days > 0
        date.add 1, 'day'
      else if offset_days < 0
        date.subtract 1, 'day'

      if is_holiday == false
        if offset_days < 0
          offset_days += 1
        else if offset_days > 0
          offset_days -= 1
    return date.format("YYYY-MM-DD")

  justdoLevelWorkingDaysOffset: (project_id, from_date, to_date) ->
    check project_id, String
    check from_date, String
    check to_date, String

    if from_date == to_date
      return 0

    justdo_level_data = @default_workdays
    if (project_obj = JD.collections.Projects.findOne(project_id))?
      resources_data = project_obj["#{JustdoResourcesAvailability.project_custom_feature_id}"]
    if (resources_data?[project_id])?
      justdo_level_data  = resources_data[project_id]

    reverse_offset = false
    if from_date > to_date
      tmp_date = from_date
      from_date = to_date
      to_date = tmp_date
      reverse_offset = true

    count = 0
    start_date = moment.utc(from_date)
    last_date = moment.utc(to_date)
    max_count = 10000
    while start_date < last_date
      date = start_date.format("YYYY-MM-DD")
      is_holiday = false
      if justdo_level_data?.holidays and (date in justdo_level_data.holidays) or \
        justdo_level_data?.working_days?[start_date.day()]?.holiday
        is_holiday = true

      if not is_holiday
        count += 1

      start_date.add(1, 'days')

      #should never happen, but just in case...
      max_count -= 1
      if max_count == 0
        throw "infinite-loop"

    if reverse_offset
      return -count
    return count
