_.extend TasksChangelogManager.prototype,
  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return

  undoOldValueTransformers: {}

  undoActivity: (activity_obj) ->
    if (transformer = @undoOldValueTransformers[activity_obj.field])?
      old_value = transformer(activity_obj)
    else
      old_value = activity_obj.old_value

    # Operation: set the changed field to it's old value
    op =
      $set:
        [activity_obj.field]: old_value

    @tasks_collection.update activity_obj.task_id, op, (err, result) ->
      if not err?
        Meteor.call "undoActivity", activity_obj._id
        return
      console.error err
      return

    return
