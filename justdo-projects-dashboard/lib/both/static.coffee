_.extend JustdoProjectsDashboard,
  project_custom_feature_id: "justdo_projects_dashboard" # Use underscores

  plugin_human_readable_name: "Project Dashboard"

  # taskExcluder will return true by default to show all tasks in the Dashboard
  # If certain tasks are meant to be excluded, implement and overwrite this method in the relavent plugin's static.coffee
  taskExcluder: (task_obj) -> true

JustdoProjectsDashboard.taskExcluder = (task_obj) ->
  if task_obj.stm_document_type is "issues" or task_obj.stm_document_type is "risks"
    return false
  return true
