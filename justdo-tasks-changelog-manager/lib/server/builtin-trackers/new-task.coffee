_.extend PACK.builtin_trackers,
  newTaskTracker: ->
    self = @

    self.tasks_collection.after.insert (userId, doc) ->
      # using 'after' in order to catch both 'insert' and 'upsert'.
      # see collections hooks documentation
      if _.isString doc._id
        obj =
          field: "_id"
          label: "_id"
          new_value: doc._id
          change_type: "created"
          task_id: doc._id
          project_id: doc.project_id
          users_added: doc.users
          by: doc.created_by_user_id

        self.logChange(obj)

      return true