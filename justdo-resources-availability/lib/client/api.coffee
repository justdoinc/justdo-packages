

_.extend JustdoResourcesAvailability.prototype,

  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()



    return

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoResourcesAvailability.project_custom_feature_id,
        installer: =>
          Tracker.autorun =>
            @resorce_availability_subscription = Meteor.subscribe "jd-resource-availability", JD.activeJustdo({_id: 1})._id
            return
          return

        destroyer: =>
          @resorce_availability_subscription.stop()
          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  # The following will open the resources config dialog.
  # if user_id is provided - then for the user in the current JustDo, else - for the entire JustDo
  displayConfigDialog: (project_id, user_id, task_id)->
    if not project_id
      project_id = JD.activeJustdo({_id: 1})._id

    config_data = {}

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

    message_template =
      JustdoHelpers.renderTemplateInNewNode(Template.justdo_resources_availability_config_dialog, config_data)

    bootbox.dialog
      title: config_data.title
      message: message_template.node
      animate: true
      className: "bootbox-new-design"

      onEscape: ->
        return true

      buttons:
        close:
          label: "Close"
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
