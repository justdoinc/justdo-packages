Template.confirm_edit_members_dialog.helpers
  usersText: (member_ids) ->
    html = ""
    i = 0
    for member_id in member_ids
      if i == 3
        html += " and another #{member_id.length - 3} users"
        break

      if i != 0
        html += ", "

      html += JustdoHelpers.displayName member_id
      i = i + 1

    return html

  batchedImmediateProcessThreshold: ->
    return JustdoDbMigrations.batched_collection_updates_immediate_process_threshold_docs

  minSecondsToProcess: ->
    # +1 in the beginning is for the first second in which we process batched_collection_updates_immediate_process_threshold_docs immediately
    min_seconds_to_process = 1 + (@tasks_count - JustdoDbMigrations.batched_collection_updates_immediate_process_threshold_docs) / JustdoDbMigrations.batched_collection_updates_max_docs_updates_per_second

    return Math.round min_seconds_to_process

  maxSecondsToProcess: ->
    max_seconds_to_process = 1 + (@tasks_count - JustdoDbMigrations.batched_collection_updates_immediate_process_threshold_docs) / (JustdoDbMigrations.batched_collection_updates_max_docs_updates_per_second / JustdoDbMigrations.batched_collection_updates_total_in_progress_jobs_to_handle_per_cycle)

    return Math.round max_seconds_to_process
