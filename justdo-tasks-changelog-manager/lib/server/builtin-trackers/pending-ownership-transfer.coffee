_.extend PACK.builtin_trackers,
  pendingOwnershipTransferTracker: ->
    self = @

    self.tasks_collection.before.update (userId, doc, fieldNames, modifier, options) ->
      if not doc.pending_owner_id and (pending_owner_id = modifier?.$set?.pending_owner_id)?
        obj =
          field: "pending_owner_id"
          label: "Transfer request (Pending)"
          new_value: pending_owner_id
          change_type: "trasnfer_pending"
          task_id: doc._id
          by: userId

        self.logChange obj

      return true

    self.tasks_collection.after.insert (userId, doc) ->
      if (pending_owner_id = doc.pending_owner_id)?
        obj =
          field: "pending_owner_id"
          label: "Transfer request (Pending)"
          new_value: pending_owner_id
          change_type: "trasnfer_pending"
          task_id: doc._id
          by: userId

        self.logChange obj

      return true
