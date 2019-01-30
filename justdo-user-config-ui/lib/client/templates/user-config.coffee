Template.user_config_dialog.helpers
  sections: ->
    user_config_ui = APP.modules.main.user_config_ui

    if not user_config_ui?
      console.warn "APP.main.user_config_ui isn't available, can't show user config dialog"

      return {}

    return user_config_ui.getSections()