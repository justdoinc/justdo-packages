Template.toggle_private_mode_user_conf.helpers
  enabled: -> APP.justdo_user_active_position.isCurrentUserShowingActivePosition()

Template.toggle_private_mode_user_conf.events
  "click .justdo-user-active-position-config": (e, tpl) ->
    cb = (err) ->
      if err?
        JustdoSnackbar.show
          text: err.reason or err
      return

    if APP.justdo_user_active_position.isCurrentUserShowingActivePosition()
      APP.justdo_user_active_position.hideUserActivePosition cb
    else
      APP.justdo_user_active_position.showUserActivePosition cb

    return
