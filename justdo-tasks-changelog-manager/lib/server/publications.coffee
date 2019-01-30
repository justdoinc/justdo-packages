_.extend TasksChangelogManager.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "taskChangelog", (task_id) ->
      check(task_id, String)

      if not @userId?
        @ready()
        return

      if not (task = self.tasks_collection.findOne(task_id))?
        @ready()

        return

      if not task.users? or task.users.indexOf(@userId) == -1
        @ready()

        return

      return self.changelog_collection.find {task_id: task_id}