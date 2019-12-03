

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
      console.log ">>>", "subscription started"
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
      console.log ">>>", "subscription stopped"
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
