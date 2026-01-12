Template.mobile_navbar.helpers
  tabs: -> 
    return APP.justdo_pwa.getMobileTabs()

  isActiveTab: (tab_id) -> 
    return APP.justdo_pwa.getActiveMobileTabId() is tab_id

  shouldRenderTab: ->
    if @listingCondition?
      return @listingCondition()

    return true

Template.mobile_navbar.events
  "click .mobile-navbar-btn": (e, tpl) ->
    APP.justdo_pwa.setActiveMobileTab($(e.currentTarget).data("tab"))

    return

Template.mobile_tabs.helpers
  activeMobileTab: ->
    return APP.justdo_pwa.getActiveMobileTab()

Template.mobile_tab_notifications.helpers
  requiredActions: -> APP.projects.modules.required_actions.getCursor({allow_undefined_fields: true, sort: {date: -1}}).fetch()

  requiredActionsCount: -> APP.projects.modules.required_actions.getCursor({fields: {_id: 1}}).count()
