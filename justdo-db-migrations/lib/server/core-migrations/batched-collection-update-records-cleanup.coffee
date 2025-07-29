APP.executeAfterAppLibCode ->
  common_batched_migration_options =
    mark_as_completed_upon_batches_exhaustion: false
    delay_before_checking_for_new_batches: 1000 * 60 * 60 * 24 # 1 day

    delay_between_batches: 1000
    batch_size: 100

    collection: APP.collections.DBMigrationBatchedCollectionUpdates

    static_query: false
    queryGenerator: ->
      #
      # IMPORTANT, if you change the following, don't forget to update the relevant collections-indexes.coffee
      # and to drop obsolete indexes (see BATCHED_COLLECTION_UPDATES_INDEX)
      #
      query =
        # If we don't care about `process_status`, we can use `docExpiryMigration` instead of `commonBatchedMigration`
        # but BATCHED_COLLECTION_UPDATES_INDEX would not be used in this case.
        process_status: "done"
        "process_status_details.last_processed":
          $lte: JustdoHelpers.getDateMsOffset(-14 * 24 * 60 * 60 * 1000) # 14 days ago

      query_options =
        fields:
          _id: 1

      return {query, query_options}

    batchProcessor: (batched_collection_update_cursor) ->
      ids_to_remove = batched_collection_update_cursor.map (batched_collection_update) -> batched_collection_update._id

      APP.collections.DBMigrationBatchedCollectionUpdates.remove {_id: {$in: ids_to_remove}}

      return ids_to_remove.length

  APP.justdo_db_migrations.registerMigrationScript "batched-collection-update-records-cleanup", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)

  return