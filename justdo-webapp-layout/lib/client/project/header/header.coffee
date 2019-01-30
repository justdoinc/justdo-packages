APP.executeAfterAppLibCode ->
  module = APP.modules.project_page
  curProj = module.helpers.curProj

  project_template_helpers = APP.modules.project_page.template_helpers

  #
  # project_header template
  #
  Template.project_header.helpers project_template_helpers

  #
  # project_header_global_layout_header_right, project_header_global_layout_header_middle templates
  #
  Template.project_header_global_layout_header_right.helpers project_template_helpers
  Template.project_header_global_layout_header_middle.helpers project_template_helpers

  #
  # project_name template
  #
  Template.project_name.helpers project_template_helpers

  Template.project_name.events
    "change #project-name": (e) ->
      curProj().updateProjectDoc({$set: {title: e.currentTarget.value}})

      $(e.currentTarget).blur()

      return

  #
  # project_settings template
  #
  Template.project_settings.helpers project_template_helpers

  Template.project_settings.helpers
    showRolesAndGroupsManager: ->
      return APP.justdo_roles?.showRolesAndGroupsManagerDialogOpenerInProjectSettingsDropdown()

  Template.project_settings.events
    "click #project-config": (e) ->
      module.project_config_ui.show()

      return

    "click #register-project-for-daily-email": (e) ->
      e.stopPropagation()

      project_obj = curProj()

      project_obj.subscribeToDailyEmail(
        not project_obj.isSubscribedToDailyEmail())

    "click .email-notifications": (e) ->
      e.stopPropagation()

      project_obj = curProj()

      project_obj.subscribeToEmailNotifications(
        not project_obj.isSubscribedToEmailNotifications())

    "click .roles-and-groups-manager": ->
      APP.justdo_roles.openRolesAndGroupsManagerDialog()

      return