_.extend JustdoDependencies,
  project_custom_feature_id: "justdo_dependencies" # Use underscores

  plugin_human_readable_name: "Dependencies"

  task_pane_tab_label: "justdo-dependencies"

  dependencies_field_id: "justdo_task_dependencies_string"
  dependencies_field_label: "Starts After"
  dependencies_field_type: "string"

  # Only tasks with the following states that have dependencies that aren't met, are considered blocked
  blocked_tasks_states: ["pending", "in-progress", "on-hold", "nil"]

  # Only tasks with the following states are considered to be non-blocking, when other tasks depends on them
  non_blocking_tasks_states: ["done"]
