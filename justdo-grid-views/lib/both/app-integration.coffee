APP.getEnv (env) ->
  options =
    projects_collection: APP.collections.Projects
    tasks_collection: APP.collections.Tasks

  APP.justdo_grid_views = new JustdoGridViews(options)

  return
