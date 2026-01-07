_.extend JustdoPwa,
  plugin_human_readable_name: "justdo-pwa"
  mobile_breakpoint: 768 # px, matches the "md" breakpoint in Bootstrap
  default_mobile_tabs: [
      _id: "main"
      label: "main"
      icon: "grid"
    ,
      _id: "notifications"
      label: "notifications_label"
      icon: "bell"
      template: "mobile_tab_notifications"
    ,
      _id: "chats"
      label: "chats_label"
      icon: "message-circle"
      template: "recent_activity_dropdown"
      template_data:
        initial_messages_to_request: 20
    ,
      _id: "bottom-pane"
      label: "bottom-pane"
      icon: "sidebar"
      listingCondition: -> 
        # Require active justdo and at least one tab to be registered
        return JD.activeJustdoId()? and not _.isEmpty(APP.justdo_project_pane?.getTabsDefinitions())
      onActivate: ->
        APP.justdo_project_pane.expand()
        APP.justdo_project_pane.enterFullScreen()
        return
      onDeactivate: ->
        APP.justdo_project_pane.collapse()
        return
    ,
      _id: "task-pane"
      label: "task-pane"
      icon: "sidebar"
      listingCondition: -> 
        # Require active item
        return JD.activeItemId()?
      onActivate: ->
        APP.modules.project_page.updatePreferences({toolbar_open: true})
        return
      onDeactivate: ->
        APP.modules.project_page.updatePreferences({toolbar_open: false})
        return
  ]