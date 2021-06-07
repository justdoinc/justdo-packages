_.extend TasksChangelogManager.prototype,
  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return

  undo: (activity_obj) ->
    @tasks_collection.update activity_obj.task_id,
      $set:
        [activity_obj.field]: activity_obj.old_value

    Meteor.call "undo", activity_obj

    return
