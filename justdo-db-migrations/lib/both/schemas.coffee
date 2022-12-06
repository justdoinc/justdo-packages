_.extend JustdoDbMigrations.prototype,
  _attachCollectionsSchemas: -> 
    # Important! we don't use simple schema on insert, since it turned out to be too expensive for
    # massive workloads insertion (specifically for massive ids_to_update arrays, it'd take long minutes
    # to finish for jobs of 20k+ ids_to_update).
    @batched_collection_updates_collection.attachSchema new SimpleSchema
      created_by: # null/undefined means created by a server process.
        type: String
        optional: true
      
      type: # One of the registered types
        type: String

      data:
        type: Object
        blackbox: true

      ids_to_update:
        type: [String]

      process_status:
        type: String
        allowedValues: ["pending", "in-progress", "done", "error", "terminated"]
        # "error" is a terminal state, once a job reached it, it can't turn back
        # "terminated" is for cases where the user requested the job to be terminated.

      process_status_details:
        type: new SimpleSchema
          total:
            type: Number # Will be initiated to ids_to_update.length

          processed: # Successfully processed ids. For example: if set to 3 the: ids_to_update[0], ids_to_update[1] and ids_to_update[2] can be assumed as *properly* processed.
            type: Number
            defaultValue: 0

          last_processed: # The date of the last time we processed docs for this job
            type: Date
            optional: true

          created_at:
            type: Date

          started_at: # The moment the process_status changed from "pending" to "in-progress"
            type: Date
            optional: true

          closed_at: # The moment the process_status changed from "pending"/"in-progress" to "done"/"error"/"terminated"
            type: Date
            optional: true

          error_data: # Will appear only if process_status is "error", will have both error trace to help figure cause, and details to help come up with a user readable message
            type: Object
            blackbox: true
            optional: true

          terminated_by: # Will appear only if process_status is "terminated"
            type: String # Similar to created_by: null/undefined means created by a server process.
            optional: true

    return
