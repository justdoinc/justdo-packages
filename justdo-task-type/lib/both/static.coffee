_.extend JustdoTaskType,
  project_custom_feature_id: "justdo_task_type" # Use underscores

  plugin_human_readable_name: "Task Type"

  plugin_integral_part_of_justdo: true # If set to true, there's no need to install this plugin. It won't show in the JustDo settings.

  core_categories: [
    {
      category_id: "default"
      label: "Types"
    }
  ]