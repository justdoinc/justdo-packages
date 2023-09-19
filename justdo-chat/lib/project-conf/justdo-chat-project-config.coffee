# curProj = -> APP.modules.project_page.curProj()

# module_id = "justdo-chat"

# Template.justdo_chat_project_config.helpers
#   isModuleEnabled: ->
#     return APP.modules.project_page.curProj().isCustomFeatureEnabled(module_id)

# Template.justdo_chat_project_config.events
#   "click .project-conf-justdo-chat-config": ->
#     proj = curProj()

#     if proj.isCustomFeatureEnabled(module_id)
#       curProj().disableCustomFeatures(module_id)
#     else
#       curProj().enableCustomFeatures(module_id)

# APP.executeAfterAppClientCode ->
#   project_page_module = APP.modules.project_page
#   project_page_module.project_config_ui.registerConfigTemplate "justdo_chat_project_config",
#     section: "extensions"
#     template: "justdo_chat_project_config"
#     priority: 50