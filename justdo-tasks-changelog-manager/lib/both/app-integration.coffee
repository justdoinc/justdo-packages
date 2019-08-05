APP.getEnv (env) ->
  APP.collections.TasksChangelog = new Mongo.Collection "changeLog"

  options = 
    changelog_collection: APP.collections.TasksChangelog
    justdo_projects_obj: APP.projects
    tasks_collection: APP.collections.Tasks

  if Meteor.isServer
    # Defined in: justdo-projects/lib/both/app-integration.coffee
    options.removed_projects_tasks_archive_collection =
      APP.collections.RemovedProjectsTasksArchiveCollection

  APP.tasks_changelog_manager = new TasksChangelogManager options

  return
