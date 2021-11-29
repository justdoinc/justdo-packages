APP.getEnv (env) ->

  options =
    projects_collection: APP.collections.Projects
    tasks_collection: APP.collections.Tasks

  APP.justdo_quick_notes = new JustdoQuickNotes(options)

  return