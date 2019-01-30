_.extend PACK.builtin_trackers,
  priorityChangesTracker: ->
    self = @

    self.tasks_collection.before.update (userId, doc, fieldNames, modifier, options) ->
      key = "priority"

      if (new_priority = modifier.$set?[key])?
        if (current_priority = doc[key])? and current_priority == new_priority
          # No change to priority field
          return

        obj =
          field: key
          label: self.tasks_collection.simpleSchema()._schema[key].label
          new_value: new_priority
          task_id: doc._id
          by: self._extractUpdatedByFromModifierOrFail(modifier)

        if new_priority > current_priority
          obj.change_type = "priority_increased"
        else
          obj.change_type = "priority_decreased"

        self.logChange(obj)