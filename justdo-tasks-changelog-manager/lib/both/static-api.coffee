_.extend TasksChangelogManager,
  getFilteredActivityLogByTime: (activity_logs) ->
    logs = []
    logs_time = {}

    activity_logs.forEach (log) ->
      log_type_id = "#{log.task_id}-#{log.field}-#{log.by}"
      # If a field is changed by the same user within 2 mins, don't display that log.
      if (newer_logs_time = logs_time[log_type_id])?
        for newer_time in newer_logs_time
          if moment(newer_time).diff(moment(log.when), "minute") < TasksChangelogManager.hide_changelog_threshold
            return

      if not logs_time[log_type_id]?
        logs_time[log_type_id] = []

      logs_time[log_type_id].push log.when

      logs.push log

      return

    return logs
