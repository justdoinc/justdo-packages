APP.getEnv (env) ->
  options =
    projects_collection: APP.collections.Projects
    tasks_collection: APP.collections.Tasks

  APP.justdo_task_type = new JustdoTaskType(options)

  APP.emit("justdo-task-type-initiated")

  return