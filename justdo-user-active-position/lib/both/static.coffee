_.extend JustdoUserActivePosition,
  project_custom_feature_id: "justdo_user_active_position"
  plugin_human_readable_name: "Collaboration Indicators"
  users_active_position_ledger_collection_name: "users_active_positions_ledger"
  users_active_position_current_collection_name: "users_active_positions_current"
  idle_time_to_consider_session_inactive: 1000 * 60 * 10 # 10 minutes
  check_user_inactive_interval: 1000 * 60 * 1 # 1 minute
  idle_time_to_consider_session_ended: 1000 * 60 * 30 # 30 minutes
