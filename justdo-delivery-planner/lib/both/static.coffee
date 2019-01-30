_.extend JustdoDeliveryPlanner,
  project_custom_feature_id: "justdo_delivery_planner" # Use underscores

  task_is_project_field_name: "p:dp:is_project"

  task_is_archived_project_field_name: "p:dp:is_archived_project"

  task_project_members_availability_field_name: "p:dp:members_availability"

  task_base_project_workdays_field_name: "p:dp:base_project_workdays"

  task_baseline_projection_data_field_name: "p:dp:baseline_projection"

  task_is_committed_field_name: "p:dp:commited"

  default_time_zone: "America/New_York" # The timezone we will use for users we can't determine their timezone

  default_simple_member_daily_availability_seconds: 60 * 60 * 3

  default_base_project_workdays: [0, 1, 1, 1, 1, 1, 0]
