share.current_recent_activity_dropdown = null # We assume only one button per app instance

Template.justdo_chat_recent_activity_button.onRendered ->
  @recent_activity_dropdown = new share.RecentActivityDropdown(@firstNode) # defined in ./recent-activity-dropdown/recent-activity-dropdown.coffee

  share.current_recent_activity_dropdown = @recent_activity_dropdown

  APP.justdo_chat.requireSubscribedUnreadChannelsCountSubscription()

  return

Template.justdo_chat_recent_activity_button.onDestroyed ->
  if @recent_activity_dropdown?
    @recent_activity_dropdown.destroy()
    @recent_activity_dropdown = null

  APP.justdo_chat.releaseRequirementForSubscribedUnreadChannelsCountSubscription()

  return

Template.justdo_chat_recent_activity_button.helpers
  unread_count: ->
    return APP.justdo_chat.getSubscribedUnreadChannelsCount() or 0

