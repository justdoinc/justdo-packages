Template.chat_bottom_windows_extra_windows_button.helpers
  extraWindows: ->
    return APP.justdo_chat._justdo_chat_bottom_windows_manager.getExtraWindows()

Template.chat_bottom_windows_extra_windows_button_item.events
  "click .window-title": ->
    @channel_object.makeWindowVisible()

    return

  "click .close-window": ->
    @channel_object.removeWindow()

    return
