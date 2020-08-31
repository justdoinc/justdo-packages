_.extend JustdoGridGantt,
  project_custom_feature_id: "justdo_grid_gantt" # Use underscores

  plugin_human_readable_name: "Grid Gantt"

  add_pseudo_field: true
  pseudo_field_id: "justdo_grid_gantt"
  pseudo_field_label: "Gantt"
  pseudo_field_type: "string"

  pseudo_field_formatter_id: "ganttFormatter"

  is_milestone_pseudo_field_id: "jgg:is_milestone"
  is_milestone_pseudo_field_label: "Gantt Milestone"

  progress_percentage_pseudo_field_id: "jgg:progress_percentage"
  progress_percentage_pseudo_field_label: "% Completed"
  progress_percentage_pseudo_field_formatter_id: "jgg:progress_percentage_formatter"



  