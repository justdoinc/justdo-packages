Template.confirm_edit_members_dialog.helpers
  usersText: (member_ids) ->
    if member_ids.length is 1
      return JustdoHelpers.displayName member_ids[0]

    first_few_users = ""
    first_few_users_count = 3
    i = 0
    for member_id in member_ids
      if i == first_few_users_count
        break

      if i != 0
        first_few_users += ", "

      first_few_users += JustdoHelpers.displayName member_id
      i = i + 1

    count = member_ids.length - first_few_users_count
    if count < 0
      count = 0

    return TAPi18n.__ "confirm_edit_member_dialog_and_other_users", {users: first_few_users, count: count}

  batchedImmediateProcessThreshold: ->
    return JustdoDbMigrations.batched_collection_updates_immediate_process_threshold_docs

  timeToProcess: ->
    min_seconds_to_process = 1 + (@tasks_count - JustdoDbMigrations.batched_collection_updates_immediate_process_threshold_docs) / JustdoDbMigrations.batched_collection_updates_max_docs_updates_per_second
    min_time_to_process = JustdoHelpers.secondsToHumanReadable Math.round(min_seconds_to_process), {include_seconds_if_gte_minute: false}

    max_seconds_to_process = 1 + (@tasks_count - JustdoDbMigrations.batched_collection_updates_immediate_process_threshold_docs) / (JustdoDbMigrations.batched_collection_updates_max_docs_updates_per_second / JustdoDbMigrations.batched_collection_updates_total_in_progress_jobs_to_handle_per_cycle)
    max_time_to_process = JustdoHelpers.secondsToHumanReadable Math.round(max_seconds_to_process), {include_seconds_if_gte_minute: false}

    return {min_time_to_process, max_time_to_process}

  minSecondsToProcess: ->
    # +1 in the beginning is for the first second in which we process batched_collection_updates_immediate_process_threshold_docs immediately

    return Math.round min_seconds_to_process

  maxSecondsToProcess: ->

    return Math.round max_seconds_to_process
