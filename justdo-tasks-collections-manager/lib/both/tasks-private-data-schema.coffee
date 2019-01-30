_.extend JustdoTasksCollectionsManager.prototype,
  _attachTasksPrivateDataCollectionSchema: ->
    Schema =
      user_id:
        label: "User ID"

        type: String

      task_id:
        label: "Task ID"

        type: String

      project_id:
        label: "JustDo ID"

        type: String

        autoValue: ->
          # If the code is not from trusted code unset the update
          if not @isFromTrustedCode
            if @isSet
              self.logger.warn "Untrusted attempt to change project_id rejected"

              return @unset()

          return # Keep this return to return undefined (as required by autoValue)

    for field_name in ["_raw_updated_date"] 
      Schema[field_name] =
        type: "skip-type-check"

        optional: true

        autoValue: ->
          # If the code is not from trusted code unset the update
          if not @isFromTrustedCode
            if @isSet
              self.logger.warn "Untrusted attempt to change #{field_name} rejected"

              return @unset()

          return # Keep this return to return undefined (as required by autoValue)

    # _raw_frozen is the marker we set to true for private data docs of tasks from
    # which a user been removed, if the user is brought back to the task, we remove
    # the flag, bringing back access to the private data the user previously held
    # on that task
    for field_name in ["_raw_frozen"]
      Schema[field_name] =
        type: Boolean

        optional: true

        autoValue: ->
          # If the code is not from trusted code unset the update
          if not @isFromTrustedCode
            if @isSet
              self.logger.warn "Untrusted attempt to change #{field_name} rejected"

              return @unset()

          return # Keep this return to return undefined (as required by autoValue)

    @tasks_private_data_collection.attachSchema Schema
