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
  Template.project_header_global_layout_header_right.helpers
    rightNavbarItems: ->
      return JD.getPlaceholderItems("project-right-navbar").reverse()

  JD.registerPlaceholderItem "members-dropdown-button",
    data:
      template: "members_dropdown_button"
      template_data: {}

    domain: "project-right-navbar"
    position: 100

  JD.registerPlaceholderItem "plugins-store-button",
    data:
      template: "plugins_store_button"
      template_data: {}

    domain: "project-right-navbar"
    position: 200

  JD.registerPlaceholderItem "project-settings",
    data:
      template: "project_settings"
      template_data: {}

    domain: "project-right-navbar"
    position: 300

  JD.registerPlaceholderItem "project-required-actions-dropdown-comp",
    data:
      template: "project_required_actions_dropdown_comp"
      template_data: {}

    domain: "global-right-navbar"
    position: 50

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
      return APP.custom_justdo_save_default_view?.isPluginInstalledOnProjectDoc(JD.activeJustdo({conf: 1}))

    settingsDropdownTopItems: ->
      return JD.getPlaceholderItems("settings-dropdown-top")

    settingsDropdownMiddleItems: ->
      return JD.getPlaceholderItems("settings-dropdown-middle")

    settingsDropdownBottomItems: ->
      return JD.getPlaceholderItems("settings-dropdown-bottom")

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

  Template.panes_controls.helpers
    isBottomPaneAvailable: -> not _.isEmpty APP.justdo_project_pane.getTabs()

    isBottomPaneOpen: -> APP.justdo_project_pane.isExpanded()

    isTaskPaneOpen: -> module.preferences.get()?.toolbar_open

  Template.panes_controls.events
    "click .task-pane-control": ->
      toolbar_open = module.preferences.get()?.toolbar_open

      module.updatePreferences({toolbar_open: not toolbar_open})

      return

    "click .bottom-pane-control": ->
      if APP.justdo_project_pane.isExpanded()
        APP.justdo_project_pane.collapse()
      else
        APP.justdo_project_pane.expand()

