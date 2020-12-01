_.extend PACK.builtin_trackers,
  newTaskTracker: ->
    self = @

    self.tasks_collection.after.insert (userId, doc) ->
      # using 'after' in order to catch both 'insert' and 'upsert'.
      # see collections hooks documentation
      if _.isString doc._id
        created_doc = _.extend {}, doc
        keys_to_remove = ["_id", "users", "users_updated_at"]
        for key, val of created_doc
          if /^priv:/.test(key) or /^_raw/.test(key)
            keys_to_remove.push key
        for key in keys_to_remove
          delete created_doc[key]

        obj =
          field: "_id"
          label: "_id"
          new_value: doc._id
          change_type: "created"
          task_id: doc._id
          project_id: doc.project_id
          users_added: doc.users
          by: doc.created_by_user_id
          created_doc: created_doc

        self.logChange(obj)

      return true