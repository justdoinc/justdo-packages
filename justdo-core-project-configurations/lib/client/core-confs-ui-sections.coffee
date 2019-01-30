APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  module.project_config_ui.registerConfigSection "basic",
    # Add to this section the configs that you want to show first,
    # without any specific title (usually very basic configurations)

    title: null # null means no title
    priority: 10

  module.project_config_ui.registerConfigSection "appearance",
    title: "Appearance"
    priority: 100

  module.project_config_ui.registerConfigSection "extensions",
    title: "Extensions"
    priority: 200
