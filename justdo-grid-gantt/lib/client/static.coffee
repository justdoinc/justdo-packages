_.extend JustdoGridGantt,
  project_custom_feature_id: "justdo_grid_gantt" # Use underscores

  plugin_human_readable_name: "Grid Gantt"

  add_pseudo_field: true
  pseudo_field_id: "justdo_grid_gantt"
  pseudo_field_label: "Gantt"
  pseudo_field_type: "string"

  pseudo_field_formatter_id: "ganttFormatter"

  # gantt_field_grid_dependencies_fields: ["start_date", "end_date", "due_date"] # Changes to these fields will trigger invalidation to the gantt field on the grid.