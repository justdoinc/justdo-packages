Template.mobile_navbar.helpers
  tabs: -> JustdoPwa.default_mobile_tabs

  isActiveTab: (tab_id) -> 
    return APP.justdo_pwa.getActiveTab() is tab_id

  shouldRenderTab: ->
    if @listingCondition?
      return @listingCondition()

    return true

Template.mobile_navbar.events
  "click .mobile-navbar-btn": (e, tpl) ->
    APP.justdo_pwa.setActiveTab($(e.currentTarget).data("tab"))

    return

Template.mobile_tabs.helpers
  getActiveTabTemplate: ->
    tab_definition = APP.justdo_pwa.getActiveTabDefinition()
    if (template = tab_definition.tab_template)?
      return template
    return

Template.mobile_tab_notifications.helpers
  requiredActions: -> APP.projects.modules.required_actions.getCursor({allow_undefined_fields: true, sort: {date: -1}}).fetch()

  requiredActionsCount: -> APP.projects.modules.required_actions.getCursor({fields: {_id: 1}}).count()

Template.mobile_tab_chats.helpers
  isLoadingRecentActivity: ->
    subscription_state = APP.justdo_chat.getSubscribedChannelsRecentActivityState()
    return subscription_state in ["no-sub", "initial-not-ready"]

  recentActivityItems: ->
    return APP.collections.JDChatRecentActivityChannels.find({}, {sort: {last_message_date: -1}}).fetch()

  getSubscribedChannelsRecentActivityState: ->
    return APP.justdo_chat.getSubscribedChannelsRecentActivityState()
