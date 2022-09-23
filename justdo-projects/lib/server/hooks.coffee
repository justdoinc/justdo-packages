_.extend Projects.prototype,
  _setupHooks: -> 
    self = @

    setDescriptionLastUpdate = (user_id, task_doc) ->
      update =
        $currentDate:
          "#{Projects.tasks_description_last_update_field_id}": true

      APP.collections.Tasks.update
        _id: task_doc._id
      , update

      private_fields_mutator =
        $currentDate:
          "#{Projects.tasks_description_last_read_field_id}": true

      APP.projects._grid_data_com._upsertItemPrivateData task_doc.project_id, task_doc._id, private_fields_mutator, user_id
      return

    APP.collections.Tasks.after.insert (user_id, task_doc) ->
      if not user_id?
        # If no user_id can be found (likely server originated call) do nothing
        return

      if (task_doc?.description)?
        setDescriptionLastUpdate user_id, task_doc
      return

    APP.collections.Tasks.before.update (user_id, task_doc, fields, modifier, options) ->
      if not user_id?
        # If no user_id can be found (likely server originated call) do nothing
        return

      if (description = modifier.$set.description) != undefined
        if description == null
          update =
            $set:
              "#{Projects.tasks_description_last_update_field_id}": null

          APP.collections.Tasks.update
            _id: task_doc._id
          , update
        else
          setDescriptionLastUpdate user_id, task_doc
      return

    return
