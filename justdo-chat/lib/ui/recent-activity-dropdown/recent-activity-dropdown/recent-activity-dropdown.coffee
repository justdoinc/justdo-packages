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
          element.element.addClass "animate slideIn shadow-lg"
          element.element.css
            top: new_position.top - 7
            left: new_position.left + 20

      $(".dropdown-menu.show").removeClass("show") # Hide active dropdown

    return

Template.recent_activity_dropdown.onCreated ->
  @loading_more_items = new ReactiveVar false

  APP.justdo_chat.requestSubscribedChannelsRecentActivity({additional_recent_activity_request: false})

  return

Template.recent_activity_dropdown.onDestroyed ->
  APP.justdo_chat.stopChannelsRecentActivityPublication()

  return

Template.recent_activity_dropdown.helpers
  recentActivityItems: ->
    return APP.collections.JDChatRecentActivityChannels.find({}, {sort: {last_message_date: -1}}).fetch()

  getSubscribedChannelsRecentActivityState: ->
    return APP.justdo_chat.getSubscribedChannelsRecentActivityState()

  loadingMoreItems: -> Template.instance().loading_more_items.get()

Template.recent_activity_dropdown.events
  "click .mark-all-activity-read": ->
    APP.justdo_chat.markAllChannelsAsRead()

    return

  "scroll .recent-activity-items-viewport": (e, tpl) ->
    viewport_bottom_position = tpl.$(".recent-activity-items-viewport").scrollTop() + $(".recent-activity-items-viewport").height()
    total_items_height = $(".recent-activity-items").height()
    more_items_container_height = $(".more-items-container").outerHeight() or 0

    if total_items_height - viewport_bottom_position - more_items_container_height < 10
      # User hit bottom
      subscribed_channels_activity_state = Tracker.nonreactive => APP.justdo_chat.getSubscribedChannelsRecentActivityState()
      if subscribed_channels_activity_state != "all" and not Template.instance().loading_more_items.get()
        tpl.loading_more_items.set true
        APP.justdo_chat.requestSubscribedChannelsRecentActivity
          onReady: ->
            tpl.loading_more_items.set false
    
    return

  "click .load-more-items": (e, tpl) ->
    e.preventDefault()
    tpl.loading_more_items.set true
    APP.justdo_chat.requestSubscribedChannelsRecentActivity
      onReady: ->
        tpl.loading_more_items.set false
    return
