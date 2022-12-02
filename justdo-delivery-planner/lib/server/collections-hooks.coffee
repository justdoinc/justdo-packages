_.extend JustdoDeliveryPlanner.prototype,
  _setupCollectionsHooks: ->
    self = @

    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      # Auto close/open projects when a task is being archived
      if not modifier.$set?
        return

      if not _.has modifier.$set, "archived"
        return
      new_archived_val = modifier.$set.archived
      being_archived = if _.isDate(new_archived_val) then true else false

      # By now we now the task is potentially changing its archived state

      if _.has modifier.$set, JustdoDeliveryPlanner.task_is_archived_project_field_name
        # If the update also involves update to the project closed/open state, we do nothing, to avoid interfering
        return

      if doc[JustdoDeliveryPlanner.task_is_project_field_name] isnt true
        # Task isn't even a project, nothing to do.
        return

      if being_archived and doc[JustdoDeliveryPlanner.task_is_archived_project_field_name] isnt true
        APP.justdo_delivery_planner.toggleTaskArchivedProjectState doc._id
      else if not being_archived and doc[JustdoDeliveryPlanner.task_is_archived_project_field_name] is true
        APP.justdo_delivery_planner.toggleTaskArchivedProjectState doc._id

      return

    return
