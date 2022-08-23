_.extend JustdoDbMigrations.prototype,
  _registerCoreCollectionUpdatesTypes: ->
    @registerBatchedCollectionUpdatesType "grid-bulk-update-from-secure-source",
      collection: APP.collections.Tasks
      use_raw_collection: true

    return