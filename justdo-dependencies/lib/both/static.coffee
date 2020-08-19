_.extend JustdoDependencies,
  project_custom_feature_id: "justdo_dependencies" # Use underscores

  plugin_human_readable_name: "Dependencies"

  task_pane_tab_label: "justdo-dependencies"

  dependencies_field_id: "justdo_task_dependencies"
  dependencies_field_label: "Starts After"                # note that at some point this will change from Start After to Dependencies
                                                          # to support other dependency types
  dependencies_field_type: "numbers_array"
  dependencies_field_schema_type: [Number]
  
  dependencies_mf_field_id: "justdo_task_dependencies_mf" # this is the machine-friendly (mf) form of the dependency data
                                                          # structure: [{ <dependency type>: <task_id> }]
  dependencies_mf_field_label: "Starts After MF"
  

  # Only tasks with the following states that have dependencies that aren't met, are considered blocked
  blocked_tasks_states: ["pending", "in-progress", "on-hold", "nil"]

  # Only tasks with the following states are considered to be non-blocking, when other tasks depends on them
  non_blocking_tasks_states: ["done"]

  is_milestone_pseudo_field_id: "jddep:is_milestone"
  is_milestone_pseudo_field_label: "Milestone"
