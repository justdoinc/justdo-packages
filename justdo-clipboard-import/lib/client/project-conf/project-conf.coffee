_.extend JustdoClipboardImport.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      module = APP.modules.project_page
      module.project_config_ui.registerConfigTemplate "justdo_clipboard_import_project_config",
        section: "extensions"
        template: "justdo_clipboard_import_project_config"
        priority: 1000

    return

module_id = JustdoClipboardImport.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_clipboard_import_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoClipboardImport.plugin_human_readable_name

Template.justdo_clipboard_import_project_config.events
  "click .project-conf-justdo-clipboard-import-config": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      curProj().disableCustomFeatures(module_id)
    else
      curProj().enableCustomFeatures(module_id)
