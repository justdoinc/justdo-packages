_.extend JustdoPwa,
  plugin_human_readable_name: "justdo-pwa"
  mobile_breakpoint: 768 # px, matches the "md" breakpoint in Bootstrap
  main_mobile_tab_id: "main"

_.extend JustdoPwa,
  default_mobile_tabs: [
      _id: JustdoPwa.main_mobile_tab_id
      label: "main"
      icon: "grid"
    ,
      _id: "notifications"
      label: "notifications_label"
      icon_template: "required_actions_bell"
      icon_template_data:
        skip_dropdown_creation: true
      tab_template: "mobile_tab_notifications"
    ,
      _id: "chats"
      label: "chats_label"
      icon_template: "justdo_chat_recent_activity_button"
      icon_template_data:
        skip_dropdown_creation: true
      tab_template: "mobile_tab_chats"
      tab_template_data:
        initial_messages_to_request: 20
    ,
      _id: "bottom-pane"
      label: "bottom-pane"
      icon: "sidebar"
      listingCondition: -> 
        # Require active justdo and the project pane to be enabled
        return JD.activeJustdoId()? and not (APP.justdo_project_pane?.getPaneState()?.disabled)
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