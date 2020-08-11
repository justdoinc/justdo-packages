_.extend Projects.prototype,
  _setupHooks: -> 
    self = @
    APP.collections.Tasks.before.update (user_id, task_doc, fields, modifier, options) ->
      if (description = modifier.$set.description) != undefined
        if description == null
          update =
            $set:
              "#{Projects.tasks_description_last_update_field_id}": null
              "#{Projects.tasks_description_last_read_field_id}": null
        else
          update =
            $currentDate:
              "#{Projects.tasks_description_last_update_field_id}": true

        APP.collections.Tasks.update
          _id: task_doc._id
        , update

      return

    return