APP.executeAfterAppLibCode ->
  # Migration to remove obsolete indexes
  indexes_to_remove = [
    {
      index_id: "users_1_reject_ownership_message_to_1"
      collection: APP.collections.Tasks
    }
    {
      index_id: "users_1_project_id_1_reject_ownership_message_to_1"
      collection: APP.collections.Tasks
    }
    {
      index_id: "project_id_1_reject_ownership_message_to_1"
      collection: APP.collections.Tasks
    }
    {
      index_id: "users_1_project_id_1_pending_owner_id_1"
      collection: APP.collections.Tasks
    }
    {
      index_id: "users_1_project_id_1"
      collection: APP.collections.Tasks
    }
    
    {
      index_id: "users_1_pending_owner_id_1"
      collection: APP.collections.Tasks
    }

    {
      index_id: "project_id_1_users_1"
      collection: APP.collections.Tasks
    }
    {
      index_id: "project_id_1_users_1_seqId_1"
      collection: APP.collections.Tasks
    }
    {
      index_id: "project_id_1_user_id_1__raw_frozen_1"
      collection: APP.collections.TasksPrivateData
    }
  ]

  for {index_id, collection}, index in indexes_to_remove
    remove_index_migration_options =
      index_id: index_id
      collection: collection
      run_if_lte_version_installed: "v7.0.3" # Adjust version as needed

    APP.justdo_db_migrations.registerMigrationScript "remove-obsolete-index-#{index_id}", JustdoDbMigrations.removeIndexMigration(remove_index_migration_options)
