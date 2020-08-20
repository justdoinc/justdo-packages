_.extend PACK.required_actions_definitions,
  ownership_transfer_rejected:
    tracker: (module_obj, project_id) ->
      # @ is the publications's @ augmented with the following methods:
      # * @required_action_added(arbitrary_id, action_date, action_data)
      # * @required_action_changed(arbitrary_id, action_date, action_data)
      # * @required_action_removed(arbitrary_id)

      self = module_obj

      tracker_query = 
        # Note, when the reject ownership transfer message is dismissed,
        # all the reject_ownership_message* fields are dismissed.
        users: @userId
        reject_ownership_message_to: @userId

      if project_id?
        tracker_query.project_id = project_id

      tracker_query_options =
        fields:
          _id: 1
          seqId: 1
          title: 1
          project_id: 1
          reject_ownership_message: 1
          reject_ownership_message_by: 1
          reject_ownership_message_updated_at: 1

      tracker = self.items_collection.find(tracker_query, tracker_query_options).observeChanges
        added: (id, data) =>
          data = _.extend {}, data, {task_id: id}

          @required_action_added id, data.reject_ownership_message_updated_at, data

        changed: (id, data) =>
          @required_action_changed id, data.reject_ownership_message_updated_at, data

        removed: (id) =>
          @required_action_removed id

      return tracker

    setupMongoIndices: ->
      # @ is the module's obj

      @items_collection._ensureIndex {
        "users": 1
        "reject_ownership_message_to": 1
      }

      @items_collection._ensureIndex {
        "users": 1
        "project_id": 1
        "reject_ownership_message_to": 1
      }

      return