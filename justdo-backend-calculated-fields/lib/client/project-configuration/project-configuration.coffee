_.extend JustdoBackendCalculatedFields.prototype,
  registerConfigTemplate: ->
    # adding meeting to the project configuration:

    APP.executeAfterAppLibCode ->
      module = APP.modules.project_page

      module.project_config_ui.registerConfigTemplate "backend_calculated_fields_config",
        section: "extensions"
        template: "backend_calculated_fields_config"
        priority: 1000

    return

curProj = -> APP.modules.project_page.curProj()

getCustomFeatureId = -> APP.justdo_backend_calculated_fields.options.custom_feature_id

Template.backend_calculated_fields_config.helpers
  isModuleEnabled: -> APP.modules.project_page.curProj().isCustomFeatureEnabled(getCustomFeatureId())

Template.backend_calculated_fields_config.events
  "click .project-conf-backend-calculated-fields-config": ->
    proj = curProj()

    custom_feature_id = getCustomFeatureId()

    if proj.isCustomFeatureEnabled(custom_feature_id)
      curProj().disableCustomFeatures(custom_feature_id)
    else
      curProj().enableCustomFeatures(custom_feature_id)

    return