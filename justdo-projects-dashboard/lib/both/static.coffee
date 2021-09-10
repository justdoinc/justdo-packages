_.extend JustdoProjectsDashboard,
  project_custom_feature_id: "justdo_projects_dashboard" # Use underscores

  plugin_human_readable_name: "Project Dashboard"

  # Use taskExcluder to exclude tasks from the Project Dashboard count.
  # Return false for tasks that you want to filter out.
  taskExcluder: (task_obj) -> true

# Another example for taskExcluder:
#
# JustdoProjectsDashboard.taskExcluder = (task_obj) ->
#   if task_obj.stm_document_type is "issues" or task_obj.stm_document_type is "risks"
#     return false
#   return true
