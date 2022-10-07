_.extend JustdoDbMigrations.prototype,
  _registerCoreCollectionUpdatesTypes: ->
    self = @

    do => # To avoid job_type from mixing with the next one.
      job_type = "add-remove-members-to-tasks"
      @registerBatchedCollectionUpdatesType job_type,
        collection: APP.collections.Tasks
        use_raw_collection: true
        data_schema: new SimpleSchema
          project_id:
            type: String
          members_to_add:
            type: [String]
            optional: true
          members_to_remove:
            type: [String]
            optional: true
          items_to_assume_ownership_of:
            type: [String]
            optional: true
          items_to_cancel_ownership_transfer_of:
            type: [String]
            optional: true
        jobsGatekeeper: (options) ->
          {data, ids_to_update, user_id} = options

          APP.projects.requireUserIsMemberOfProject data.project_id, user_id

          if (not data?.members_to_add? or _.isEmpty(data.members_to_add)) and (not data?.members_to_remove? or _.isEmpty(data.members_to_remove))
            throw self._error "invalid-job-data", "For jobs of type #{job_type} at least one of the fields members_to_add/members_to_remove should be provided in the job's data object (and be non-empty)"

          return
        queryGenerator: (ids_to_update, data, perform_as) ->
          console.log "WE ARE HERE", {ids_to_update, data, perform_as}
          return

      return

    return