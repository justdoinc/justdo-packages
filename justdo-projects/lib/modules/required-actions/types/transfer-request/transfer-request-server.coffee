_.extend PACK.required_actions_definitions,
  transfer_request:
    tracker: (module_obj, project_id) ->
      # @ is the publications's @ augmented with the following methods:
      # * @required_action_added(arbitrary_id, action_date, action_data)
      # * @required_action_changed(arbitrary_id, action_date, action_data)
      # * @required_action_removed(arbitrary_id)

      self = module_obj

      tracker_query = 
        users: @userId
        pending_owner_id: @userId

      if project_id?
        tracker_query.project_id = project_id

      tracker_query_options = 
        fields: 
          _id: 1
          seqId: 1
          title: 1
          project_id: 1 
          owner_id: 1 
          pending_owner_id: 1 
          pending_owner_updated_at: 1

      tracker = self.items_collection.find(tracker_query, tracker_query_options).observeChanges
        added: (id, data) =>
          data = _.extend {}, data, {task_id: id}

          @required_action_added id, data.pending_owner_updated_at, data

        changed: (id, data) =>
          @required_action_changed id, data.pending_owner_updated_at, data

        removed: (id) =>
          @required_action_removed id

      return tracker

    setupMongoIndices: ->
      # @ is the _module's obj (Even in a comment the transpiler is catching the word mod ule and causing a break to the build hence _ was added)

      @items_collection._ensureIndex {
        "users": 1
        "pending_owner_id": 1
      }

      @items_collection._ensureIndex {
        "users": 1
        "project_id": 1
        "pending_owner_id": 1
      }

      return