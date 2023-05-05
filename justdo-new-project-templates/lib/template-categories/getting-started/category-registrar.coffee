APP.getEnv (env) ->
  if not APP.justdo_new_project_templates?
    return
  
  APP.justdo_projects_templates?.registerCategory
    id: "getting-started"
    label: "Getting Started"
    order: 0

  return