_.extend TasksChangelogManager.prototype,
  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return

  undoActivity: (activity_obj) ->
    # Operation: set the changed field to it's old value
    op =
      $set:
        [activity_obj.field]: activity_obj.old_value

    @tasks_collection.update activity_obj.task_id, op, (err, result) ->
      if not err?
        Meteor.call "undoActivity", activity_obj._id
        return
      console.error err
      return

    return
