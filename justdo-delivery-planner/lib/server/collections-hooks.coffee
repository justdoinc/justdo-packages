_.extend JustdoDeliveryPlanner.prototype,
  _setupCollectionsHooks: ->
    self = @

    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      if not _.has modifier.$set, "archived"
        return

      if _.isDate modifier.$set?.archived
        if doc[JustdoDeliveryPlanner.task_is_project_field_name]
          APP.justdo_delivery_planner.toggleTaskArchivedProjectState doc._id

      return

    return
