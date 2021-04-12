_.extend Projects,
  guest_user_help_instruction: """
    A Guest works like a standard, non-Admin member. The only difference from a standard JustDo member is that rather than the complete JustDo members' list, Guests can only see and interact with members of the tasks that are shared with them.

    NOTE: All past activities of tasks shared with a Guest, will be visible to the Guest.
  """

  tasks_description_last_update_field_id: "description_last_update"
  tasks_description_last_read_field_id: "priv:description_last_read"

  not_hideable_states: ["pending", "in-progress", "done", "will-not-do"]

  # Forbidden fields should never pass through the wire to the client
  tasks_forbidden_fields: [
    "_raw_updated_date", "_raw_added_users_dates", "_raw_removed_users_dates", "_raw_removed_users", "_raw_removed_date", "_secret"]

  tasks_private_fields_docs_initial_payload_redundant_fields: ["_id", "project_id", "user_id", "_raw_updated_date"]

  grid_init_payload_cache_max_age_seconds: 60 * 15