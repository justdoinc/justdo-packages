_.extend JustdoUserActivePosition.prototype,
  _setupDbMigrations: ->
    migration_name = "#{JustdoUserActivePosition.users_active_position_ledger_collection_name}-doc-expiry"
    APP.justdo_db_migrations.registerMigrationScript migration_name, JustdoDbMigrations.docExpiryMigration
      delay_between_batches: 1000
      batch_size: 5000
      collection: APP.collections.UsersActivePositionsLedger
      ttl: 12 * 31 * 24 * 60 * 60 * 1000 # 12 months
      created_at_field: "time"
      exec_interval: 1 * 60 * 60 * 1000 # 1 hour
      last_run_record_name: "#{migration_name}-last-run"

    return