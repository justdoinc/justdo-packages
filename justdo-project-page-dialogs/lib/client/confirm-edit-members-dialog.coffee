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
    min_seconds_to_process = 1 + (@tasks_count - JustdoDbMigrations.batched_collection_updates_immediate_process_threshold_docs) / 0.5
    min_time_to_process = JustdoHelpers.secondsToHumanReadable Math.round(min_seconds_to_process), {include_seconds_if_gte_minute: false}

    max_seconds_to_process = 1 + (@tasks_count - JustdoDbMigrations.batched_collection_updates_immediate_process_threshold_docs) / 0.1
    max_time_to_process = JustdoHelpers.secondsToHumanReadable Math.round(max_seconds_to_process), {include_seconds_if_gte_minute: false}

    return {min_time_to_process, max_time_to_process}

  minSecondsToProcess: ->
    # +1 in the beginning is for the first second in which we process batched_collection_updates_immediate_process_threshold_docs immediately

    return Math.round min_seconds_to_process

  maxSecondsToProcess: ->

    return Math.round max_seconds_to_process
