_.extend JustdoDeliveryPlanner.prototype,
  _setupCollectionsHooks: ->
    self = @

    self.tasks_collection.before.update (user_id, doc, field_names, modifier, options) ->
      if not _.has modifier.$set, "archived"
        return

      archived = modifier.$set?.archived

      changelog_msg = "unarchived the task."

      if _.isDate archived
        changelog_msg = "archived the task."
        if doc["p:dp:is_project"]
          modifier.$set["p:dp:is_archived_project"] = true

      APP.tasks_changelog_manager.logChange
        field: "archived"
        label: "Archived"
        change_type: "custom"
        task_id: doc._id
        by: user_id
        new_value: changelog_msg

      return

    return
