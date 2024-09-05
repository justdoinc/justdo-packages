APP.getEnv (env) ->
  if JustdoHelpers.getClientType(env) == "web-app"
    APP.modules.main.user_config_ui.registerConfigSection "themes-selector",
      title: "themes_selector_config_title"
      priority: 100

    APP.modules.main.user_config_ui.registerConfigTemplate "high-contrast-mode-setter",
      section: "themes-selector"
      template: "themes_selector"
      priority: 100

  return
