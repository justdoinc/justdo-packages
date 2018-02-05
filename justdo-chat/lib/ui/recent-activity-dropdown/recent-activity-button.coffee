share.current_recent_activity_dropdown = null # We assume only one button per app instance

Template.justdo_chat_recent_activity_button.onRendered ->
  @recent_activity_dropdown = new share.RecentActivityDropdown(@firstNode) # defined in ./recent-activity-dropdown/recent-activity-dropdown.coffee

  share.current_recent_activity_dropdown = @recent_activity_dropdown

  @subscribed_unread_channels_count_subscription =
    APP.justdo_chat.subscribeSubscribedUnreadChannelsCount()

  return

Template.justdo_chat_recent_activity_button.onDestroyed ->
  if @recent_activity_dropdown?
    @recent_activity_dropdown.destroy()
    @recent_activity_dropdown = null

  @subscribed_unread_channels_count_subscription.stop()

  return

Template.justdo_chat_recent_activity_button.helpers
  unread_count: ->
    return APP.collections.JDChatInfo.findOne("subscribed_unread_channels_count")?.count or 0
