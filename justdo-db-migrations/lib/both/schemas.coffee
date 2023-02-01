_.extend JustdoDbMigrations.prototype,
  _attachCollectionsSchemas: -> return

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