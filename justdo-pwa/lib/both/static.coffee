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
      tab_template: "mobile_tab_notifications"
    ,
      _id: "chats"
      label: "chats_label"
      icon: "message-circle"
      onActivate: ->
        APP.justdo_chat.requestSubscribedChannelsRecentActivity({additional_recent_activity_request: false})
        return
      onDeactivate: ->
        APP.justdo_chat.stopChannelsRecentActivityPublication()
        return
      tab_template: "mobile_tab_chats"
    ,
      _id: "bottom-pane"
      label: "bottom-pane"
      icon: "sidebar"
      listingCondition: -> JD.activeJustdoId()?
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
      listingCondition: -> JD.activeJustdoId()?
      onActivate: ->
        APP.modules.project_page.updatePreferences({toolbar_open: true})
        return
      onDeactivate: ->
        APP.modules.project_page.updatePreferences({toolbar_open: false})
        return
  ]