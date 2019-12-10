APP.getEnv (env) ->
  if JustdoHelpers.getClientType(env) == "web-app"
    APP.isJustdoLabsFeaturesEnabled ->
      APP.modules.main.user_config_ui.registerConfigSection "themes-selector",
        title: "Themes Selector"
        priority: 100

      APP.modules.main.user_config_ui.registerConfigTemplate "high-contrast-mode-setter",
        section: "themes-selector"
        template: "themes_selector"
        priority: 100

  return
