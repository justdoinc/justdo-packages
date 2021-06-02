_.extend TasksChangelogManager.prototype,
  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return

  undo: (activity_obj) -> Meteor.call "undo", activity_obj
