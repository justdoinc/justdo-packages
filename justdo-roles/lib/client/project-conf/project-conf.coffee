_.extend JustdoRoles.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_roles_project_config",
        section: "extensions"
        template: "justdo_roles_project_config"
        priority: 100

    return

  registerConfigSectionTemplate: ->
    module = APP.modules.project_page

    APP.executeAfterAppClientCode ->
      module.project_config_ui.registerConfigSection "roles-and-groups",
        title: "Roles & Groups" # null means no title
        priority: 10

      module.project_config_ui.registerConfigTemplate "roles-and-groups",
        section: "roles-and-groups"
        template: "justdo_roles_project_config_section"
        priority: 100

    return

  unregisterConfigSectionTemplate: ->
    module = APP.modules.project_page

    APP.executeAfterAppClientCode ->
      module.project_config_ui.unregisterConfigSection "roles-and-groups"

    return

module_id = JustdoRoles.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_roles_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

Template.justdo_roles_project_config.events
  "click .project-conf-justdo-roles-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)

    return

Template.justdo_roles_project_config_section.events
  "click .launch-justdo-roles-config": ->
    $(".bootbox-close-button").click()

    APP.justdo_roles.openRolesAndGroupsManagerDialog()

    return
