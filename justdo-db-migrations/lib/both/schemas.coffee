_.extend JustdoDbMigrations.prototype,
  _attachCollectionsSchemas: -> 
    APP.collections.DBMigrationBatchedCollectionUpdates.attachSchema new SimpleSchema
      created_by:# "DANIEL", <- null will mean server operation, otherwise a userId
        type: String
        optional: true
      
      type:
        type: String

      # ERADACTED (we'll get from the types registrar) : collection: "tasks" # <- for security we'll have hard limit for which collections can be updated using this mechanism
      meta_data:
        type: Object
        blackbox: true

      ids_to_update:
        type: [String]
      
      modifier:
        type: String # modifier cannot be saved to mongodb directly, need to convert to String first
      #{$addToSet: {users: {$each: ["DONALD WU"]}}}

      process_status: # "" # "pending", "in-progress", "done", "error"
        type: String

      process_status_details: 
        type: new SimpleSchema
          processed:
            type: Number
            defaultValue: 0

    return

# Phase 1 take the naive approach: process all the jobs in every run of the "migration" but give each up to 1000 per cycle.

# DBMigrationBatchedCollectionUpdates
# {
#     type: "users-update", <- Arbitrary value representing the type of the operation
#     created_by: "DANIEL", <- null will mean server operation, otherwise a userId
#     # ERADACTED (we'll get from the types registrar) : collection: "tasks" # <- for security we'll have hard limit for which collections can be updated using this mechanism
#     meta_data: { # Specific to type, in that case "users-update"
#         project_id: "XXX"
#     }
#     ids_to_update: [0, 1 ..., ],
#     batch_operation: {$addToSet: {users: {$each: ["DONALD WU"]}}}
#     process_status: "" # "pending", "in-progress", "done", "error"
#     process_status_details: {
#         processed: 1000
#     }
# }