APP.getEnv (env) ->
  APP.collections.QuickNotes = new Mongo.Collection "quick_notes"

  options =
    projects_collection: APP.collections.Projects
    tasks_collection: APP.collections.Tasks
    quick_notes_collection: APP.collections.QuickNotes

  APP.justdo_quick_notes = new JustdoQuickNotes(options)

  return
