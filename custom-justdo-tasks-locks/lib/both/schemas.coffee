_.extend CustomJustdoTasksLocks.prototype,
  _attachCollectionsSchemas: ->
    Schema =
      "#{CustomJustdoTasksLocks.locking_users_task_field}":
        label: "Users Locking From Delete"
        type: [String]
        optional: true
        autoValue: ->
          # If the code is not from trusted code unset the update,
          # only api calls should be able to set
          if not @isFromTrustedCode
            if @isSet
              console.warn "Untrusted attempt to change #{CustomJustdoTasksLocks.locking_users_task_field} rejected"

              return @unset()

          return

    @tasks_collection.attachSchema Schema

    return