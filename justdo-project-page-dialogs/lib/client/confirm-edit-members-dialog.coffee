remove_seconds_reg = /\sand\s\d+\sseconds/

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

  timeToProcess: ->
    min_seconds_to_process = 1 + (@tasks_count - JustdoDbMigrations.batched_collection_updates_immediate_process_threshold_docs) / JustdoDbMigrations.batched_collection_updates_max_docs_updates_per_second
    min_time_to_process = JustdoHelpers.secondsToHumanReadable Math.round min_seconds_to_process
    min_time_to_process = min_time_to_process.replace remove_seconds_reg, ""

    max_seconds_to_process = 1 + (@tasks_count - JustdoDbMigrations.batched_collection_updates_immediate_process_threshold_docs) / (JustdoDbMigrations.batched_collection_updates_max_docs_updates_per_second / JustdoDbMigrations.batched_collection_updates_total_in_progress_jobs_to_handle_per_cycle)
    max_time_to_process = JustdoHelpers.secondsToHumanReadable Math.round max_seconds_to_process
    max_time_to_process = max_time_to_process.replace remove_seconds_reg, ""

    return {min_time_to_process, max_time_to_process}

  minSecondsToProcess: ->
    # +1 in the beginning is for the first second in which we process batched_collection_updates_immediate_process_threshold_docs immediately

    return Math.round min_seconds_to_process

  maxSecondsToProcess: ->

    return Math.round max_seconds_to_process
