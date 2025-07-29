_.extend JustdoDbMigrations.prototype,
  _ensureIndexesExists: ->
    # BATCHED_COLLECTION_UPDATES_INDEX
    APP.collections.DBMigrationBatchedCollectionUpdates._ensureIndex
      "process_status": -1
      "process_status_details.last_processed": 1

    return