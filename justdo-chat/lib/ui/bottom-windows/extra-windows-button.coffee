Template.chat_bottom_windows_extra_windows_button.helpers
  extraWindows: ->
    return APP.justdo_chat._justdo_chat_bottom_windows_manager.getExtraWindows()

Template.chat_bottom_windows_extra_windows_button_item.events
  "click .window-title": ->
    @channel_object.makeWindowVisible()

    return

  "click .close-window": (e) ->
    @channel_object.removeWindow()

    e.stopPropagation() # Note onDestroyed below updates dropdown position.

    return

Template.chat_bottom_windows_extra_windows_button_item.onDestroyed =>
  # If the chat-extra-windows-button is shown, update its position upon removal
  $(".chat-extra-windows-button.show .chat-extra-windows-icon").dropdown("update")

  return