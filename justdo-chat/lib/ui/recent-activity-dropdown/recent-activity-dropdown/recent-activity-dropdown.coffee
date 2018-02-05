share.RecentActivityDropdown = JustdoHelpers.generateNewTemplateDropdown "recent-activity-dropdown", "recent_activity_dropdown",
  custom_bound_element_options:
    close_button_html: null

  updateDropdownPosition: ($connected_element) ->
    @$dropdown
      .position
        of: $connected_element
        my: "right top"
        at: "right bottom"
        collision: "fit fit"
        using: (new_position, details) =>
          target = details.target
          element = details.element

          element.element.css
            top: new_position.top + 4
            left: new_position.left + 20

    return

Template.recent_activity_dropdown.onCreated ->
  @subscribed_channels_recent_activity_subscription =
    APP.justdo_chat.subscribeSubscribedChannelsRecentActivity({limit: 1000}) # XXX remove limit when implementing incremental loading

  return

Template.recent_activity_dropdown.onDestroyed ->
  @subscribed_channels_recent_activity_subscription.stop()

  return

Template.recent_activity_dropdown.helpers
  recentActivityItems: ->
    return APP.collections.JDChatRecentActivityChannels.find({}, {sort: {last_message_date: -1}}).fetch()

Template.recent_activity_dropdown.events
  "click .mark-all-activity-read": ->
    APP.justdo_chat.markAllChannelsAsRead()

    return