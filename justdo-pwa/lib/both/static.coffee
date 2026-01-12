_.extend JustdoPwa,
  plugin_human_readable_name: "justdo-pwa"
  mobile_breakpoint: 768 # px, matches the "md" breakpoint in Bootstrap
  main_mobile_tab_id: "main"

_.extend JustdoPwa,
  default_mobile_tabs: [
      _id: JustdoPwa.main_mobile_tab_id
      label: "main"
      order: 100
      icon: "grid"
    ,
      _id: "notifications"
      label: "notifications_label"
      icon_template: "required_actions_bell"
      icon_template_data:
        skip_dropdown_creation: true
      tab_template: "mobile_tab_notifications"
  ]