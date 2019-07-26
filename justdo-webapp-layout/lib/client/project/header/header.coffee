APP.executeAfterAppLibCode ->
  module = APP.modules.project_page
  curProj = module.helpers.curProj

  project_template_helpers = APP.modules.project_page.template_helpers

  #
  # project_header template
  #
  Template.project_header.helpers project_template_helpers

  Template.project_header.helpers
    aboveProjectHeaderItems: ->
      return module.getExtensionsPlaceholdersItems("above-project-header")

    belowProjectHeaderItems: ->
      return module.getExtensionsPlaceholdersItems("below-project-header")

  #
  # project_header_global_layout_header_right, project_header_global_layout_header_middle templates
  #
  Template.project_header_global_layout_header_right.helpers project_template_helpers
  Template.project_header_global_layout_header_right.helpers
    rightNavbarItems: ->
      return module.getPlaceholderItems("project-right-navbar")

  module.registerPlaceholderItem "members-dropdown-button",
    data:
      template: "members_dropdown_button"
      template_data: {}

    domain: "project-right-navbar"
    position: 100

  module.registerPlaceholderItem "plugins-store-button",
    data:
      template: "plugins_store_button"
      template_data: {}

    domain: "project-right-navbar"
    position: 200

  module.registerPlaceholderItem "project-settings",
    data:
      template: "project_settings"
      template_data: {}

    domain: "project-right-navbar"
    position: 300

  module.registerPlaceholderItem "project-required-actions-dropdown-comp",
    data:
      template: "project_required_actions_dropdown_comp"
      template_data: {}

    domain: "project-right-navbar"
    position: 400

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

    customJustdoSaveDefaultViewEnabled: ->
      return APP.custom_justdo_save_default_view?.isPluginInstalledOnProjectDoc(curProj()?.getProjectDoc())

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

    "click .reset-default-views-columns": ->
      APP.custom_justdo_save_default_view?.resetUserViews()

      return

    "click .set-current-columns-structure-as-default": ->
      APP.custom_justdo_save_default_view?.saveCurrentViewAsDefaultViewForActiveProject()

      return

      
      