APP.getEnv (env) ->
  if not APP.justdo_new_project_templates?
    return
  
  APP.justdo_projects_templates?.registerCategory
    id: "getting-started"
    label_i18n: "project_templates_getting_started_label"
    order: 0

  return