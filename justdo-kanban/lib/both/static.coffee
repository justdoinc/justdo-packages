_.extend JustdoKanban,
  project_custom_feature_id: "justdo_kanban" # Use underscores

  plugin_human_readable_name: "Kanban"

  add_pseudo_field: false
  pseudo_field_id: "justdo_kanban"
  pseudo_field_label: "justdo-kanban"
  pseudo_field_type: "string"

  default_kanban_active_board_field_id: "state"
  default_kanban_boards_limit: 100

  user_task_kanban_view_state_field_id: "priv:kanban"