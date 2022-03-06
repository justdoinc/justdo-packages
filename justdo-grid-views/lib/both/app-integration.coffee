APP.getEnv (env) ->
  APP.collections.GridViews = new Mongo.Collection "grid_views"

  options =
    projects_collection: APP.collections.Projects
    tasks_collection: APP.collections.Tasks
    grid_views_collection: APP.collections.GridViews

  APP.justdo_grid_views = new JustdoGridViews(options)

  return
