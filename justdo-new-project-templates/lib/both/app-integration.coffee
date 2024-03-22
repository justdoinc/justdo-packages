APP.getEnv (env) ->
  if env.LANDING_PAGE_TYPE isnt "marketing"
    return

  options =
    projects_collection: APP.collections.Projects
    tasks_collection: APP.collections.Tasks
    app_type: JustdoHelpers.getClientType env

  APP.justdo_new_project_templates = new JustdoNewProjectTemplates(options)

  return
