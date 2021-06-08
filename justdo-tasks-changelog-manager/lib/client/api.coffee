_.extend TasksChangelogManager.prototype,
  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return

  undo: (activity_obj) ->
    # Operation: set the changed field to it's old value
    op =
      $set:
        [activity_obj.field]: activity_obj.old_value

    @tasks_collection.update activity_obj.task_id, op, (err, result) ->
      if not err?
        Meteor.call "undo", activity_obj
        return

      console.error err
      return

    return
