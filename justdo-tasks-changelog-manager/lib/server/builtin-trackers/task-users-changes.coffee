_.extend PACK.builtin_trackers,
  taskUsersChangesTracker: ->
    self = @

    self.tasks_collection.before.update (userId, doc, fieldNames, modifier, options) ->
      #
      # Changes to users
      #
      if modifier.$pull?.users?.$in? or modifier.$push?.users?.$each?
        obj =
          field: 'users'
          label: 'Users'
          change_type: 'users_change'
          task_id: doc._id
          project_id: doc.project_id
          by: self._extractUpdatedByFromModifierOrFail(modifier)

        if modifier.$pull?.users?.$in?
          obj.users_removed = modifier.$pull.users.$in

        if modifier.$push?.users?.$each?
          obj.users_added = modifier.$push.users.$each

        self.logChange(obj)
