_.extend JustdoDbMigrations.prototype,
  _registerCoreCollectionUpdatesTypes: ->
    self = @

    do => # To avoid job_type from mixing with the next one.
      job_type = "add-remove-members-to-tasks"
      @registerBatchedCollectionUpdatesType job_type,
        collection: APP.collections.Tasks
        use_raw_collection: true
        data_schema: new SimpleSchema
          add:
            type: [String]
            optional: true
          remove:
            type: [String]
            optional: true
        dataValidator: (data, perform_as) ->
          if (not data?.add? or _.isEmpty(data.add)) and (not data?.remove? or _.isEmpty(data.remove))
            throw self._error "invalid-job-data", "For jobs of type #{job_type} at least one of the fields add/remove should be provided in the job's data object (and be non-empty)"

          return
        queryGenerator: (data, perform_as) ->
          console.log {data, perform_as}
          return

      return

    return