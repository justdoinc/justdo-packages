_.extend JustdoDeliveryPlanner.prototype,
  _setupCollectionsHooks: ->
    self = @

    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      # Auto close/open projects when a task is being archived
      if not modifier.$set?
        return

      if (not _.has(modifier.$set, "archived") and not _.has(modifier.$set, JustdoDeliveryPlanner.task_is_archived_project_field_name)) or
          (_.has(modifier.$set, "archived") and _.has(modifier.$set, JustdoDeliveryPlanner.task_is_archived_project_field_name))
        return
      
      if  _.has(modifier.$set, "archived")
        if (modifier.$set.archived? and doc[JustdoDeliveryPlanner.task_is_archived_project_field_name] != true) or
            (modifier.$set.archived == null and doc[JustdoDeliveryPlanner.task_is_archived_project_field_name] == true)
          modifier.$set[JustdoDeliveryPlanner.task_is_archived_project_field_name] = not doc[JustdoDeliveryPlanner.task_is_archived_project_field_name]
      else if _.has(modifier.$set, JustdoDeliveryPlanner.task_is_archived_project_field_name)
        if modifier.$set[JustdoDeliveryPlanner.task_is_archived_project_field_name] == false and doc.archived?
          modifier.$set.archived = null

      return

    return
