_.extend JustdoSiteAdmins.prototype,
  _setupClearServerVitalsLogDbMigration: ->
    APP.executeAfterAppLibCode =>
      common_batched_migration_options =
        delay_between_batches: 1000
        batch_size: 100
        mark_as_completed_upon_batches_exhaustion: false
        delay_before_checking_for_new_batches: JustdoSiteAdmins.server_vital_logs_expiry_interval_ms
        collection: @server_vitals_collection

        queryGenerator: ->
          query =
            long_term: 
              $ne: true
            createdAt:
              $lte: moment().subtract(JustdoSiteAdmins.server_vital_logs_ttl_days, "days").toDate()
          query_options =
            fields:
              _id: 1
          return {query, query_options}
        static_query: false

        batchProcessor: (cursor) ->
          doc_ids_for_removal = cursor.map (doc) -> doc._id
          APP.justdo_site_admins.server_vitals_collection.direct.remove {_id: {$in: doc_ids_for_removal}}
          return _.size doc_ids_for_removal

      APP.justdo_db_migrations.registerMigrationScript "server-vitals-cleanup", JustdoDbMigrations.commonBatchedMigration(common_batched_migration_options)

      return
      