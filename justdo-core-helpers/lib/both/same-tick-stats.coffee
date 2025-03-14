JustdoCoreHelpers.report_all_stats = false
JustdoCoreHelpers.report_optimization_issues = false
JustdoCoreHelpers.allow_break_if_threshold_reached = false

temporary_sensitivity_decrease_factor = 5

stats_key = "__stats"

pauseResumeThreshold = (val) ->
  message = ""
  if val.total_clones_time > 25
    message += "Pausing/Resuming the observers of a collection took #{val.total_clones_time}ms. "
  if val.total_clones > 50
    message += "Pausing/Resuming the observers of a collection involved #{val.total_clones} clones. "
  if val.total_compare_time > 50
    message += "Resuming the observers of a collection took #{val.total_compare_time}ms. "

  if message.length == 0
    return undefined

  return message

thresholds =
  # Example:
  # 
  # "ejson-clone":
  #   threshold_type: "regular" / "prefix" # if unset defaults to "regular"
  #                                       # For regular we expect a full stat-key cache
  #                                       # For prefix we trim everything after the ::
  #                                       # Note that message will be called with both message(val, key) ->
  #                                       # so it can be customized for the specific key that triggered it
  #   threshold: 50 / Function            # If is function, undefined will be regarded as a non-breached threshold,
  #                                       # a non undefined value will be used as the message (instead of the message
  #                                       # option that is ignored if a function is used to define the threshold)
  #   message: (val) -> "There were #{val} EJSON.clone calls in the same tick" # Ignored if threshold is a function
  #   break_if_threshold_reached: "once" # Set to "once" / "always" or use undefined to avoid break.
  #                                      # break will happen only if JustdoCoreHelpers.allow_break_if_threshold_reached is true

  "ejson-clone":
    threshold_type: "regular"
    threshold: 50 * temporary_sensitivity_decrease_factor
    message: (val) -> "There were #{val} EJSON.clone calls in the same tick"
    break_if_threshold_reached: "once" # Set to "once" / "always" or use undefined to avoid

  "ejson-parse":
    threshold_type: "regular"
    threshold: 10 * temporary_sensitivity_decrease_factor
    message: (val) -> "There were #{val} EJSON.parse calls in the same tick"
    break_if_threshold_reached: undefined

  "minimongo-find":
    threshold_type: "regular"
    threshold: 25 * temporary_sensitivity_decrease_factor
    message: (val) -> "There were #{val} minimongo finds in the same tick"
    break_if_threshold_reached: undefined

  "minimongo-find-without-fields-options":
    threshold_type: "prefix"
    threshold: 1
    message: (val) -> "There were #{val} minimongo finds without the fields options in the same tick"
    break_if_threshold_reached: undefined

  "minimongo-find-not-by-id":
    threshold_type: "regular"
    threshold: 10 * temporary_sensitivity_decrease_factor
    message: (val) -> "There were #{val} minimongo finds not-by-id in the same tick"
    break_if_threshold_reached: undefined

  "same-tick-cache-clear-time":
    threshold_type: "regular"
    threshold: 250
    message: (val) -> "A tick took more than #{val} ms to execute" # "at least", because clear_setupped_time isn't set immediately when the tick start
    break_if_threshold_reached: undefined

  "minimongo-find-not-by-id-total-scanned-docs":
    threshold_type: "regular"
    threshold: 1000
    message: (val) -> "More than #{val} minimongo documents scanned in the same tick"
    break_if_threshold_reached: undefined

  "minimongo-find-not-by-id-total-time-ms":
    threshold_type: "regular"
    threshold: 100
    message: (val) -> "More than #{val} ms spent scanning minimongo documents"
    break_if_threshold_reached: undefined

  "minimongo-find-not-by-id-total-sort-time-ms":
    threshold_type: "regular"
    threshold: 50
    message: (val) -> "More than #{val} ms spent sorting minimongo documents"
    break_if_threshold_reached: undefined

  "minimongo-reactive-observer-registered":
    threshold_type: "prefix"
    threshold: 20 * temporary_sensitivity_decrease_factor
    message: (val, key) ->
      collection_name = JustdoCoreHelpers._getSameTickStatsTrimmedVal(key)?.split(":")?[1]

      ret = "More than #{val} observers were set in the same tick"
      if collection_name?
        ret += " on collection: #{collection_name}"
      
      return ret
    break_if_threshold_reached: "once"

  "minimongo-reactive-observer-total-running":
    threshold_type: "prefix"
    threshold: 30 * temporary_sensitivity_decrease_factor
    message: (val, key) ->
      collection_name = JustdoCoreHelpers._getSameTickStatsTrimmedVal(key)?.split(":")?[1]

      return "More than #{val} reactive observers are running on collection: #{collection_name}"
    break_if_threshold_reached: undefined

  "minimongo-pause-observer-stats":
    threshold_type: "prefix"
    threshold: pauseResumeThreshold
    break_if_threshold_reached: "once"

  "minimongo-resume-observer-stats":
    threshold_type: "prefix"
    threshold: pauseResumeThreshold
    break_if_threshold_reached: "once"

JustdoCoreHelpers.registerSameTickCachePreClearProcedure ->
  stats = JustdoCoreHelpers.sameTickCacheGet(stats_key)

  if not stats?
    return

  for stat_key, val of stats
    if not (threshold_def = thresholds[stat_key])?
      if not (threshold_def = thresholds[JustdoCoreHelpers._getSameTickStatsTrimmedKey(stat_key)])? or threshold_def?.threshold_type != "prefix"
        continue

    if _.isFunction threshold_def.threshold
      if (message = threshold_def.threshold(val))?
        JustdoCoreHelpers.reportSameTickStatsOptimizationIssue(message + " (#{stat_key})")
    else
      if val >= threshold_def.threshold
        JustdoCoreHelpers.reportSameTickStatsOptimizationIssue(threshold_def.message(val, stat_key) + " (#{stat_key})")

  if JustdoCoreHelpers.report_all_stats
    console.log "STATS", stats

  return

_.extend JustdoCoreHelpers,
  reportOptimizationIssue: (message, data) ->
    if JustdoCoreHelpers.report_optimization_issues
      console.error "[OPTIMIZATION ISSUE] #{message}", data

    return

  reportSameTickStatsOptimizationIssue: (message) ->
    JustdoCoreHelpers.reportOptimizationIssue(message, JustdoCoreHelpers.sameTickCacheGet(stats_key))
    return

  _getSameTickStatsObject: ->
    stats = JustdoCoreHelpers.sameTickCacheGet(stats_key)

    if typeof stats != "object"
      stats =
        tick_id: JustdoCoreHelpers.getTickUid()

      JustdoCoreHelpers.sameTickCacheSet(stats_key, stats)

    return stats

  _getSameTickStatsTrimmedKey: (key) ->
    return key.substr(0, key.indexOf("::"))

  _getSameTickStatsTrimmedVal: (key) ->
    return key.substr(key.indexOf("::") + 2)

  _getSameTickStatsThresholdDefForKey: (key) ->
    if (threshold_def = thresholds[key])?
      return threshold_def

    trimmed_key = JustdoCoreHelpers._getSameTickStatsTrimmedKey(key)

    if thresholds[trimmed_key]?.threshold_type == "prefix"
      return thresholds[trimmed_key]

    return undefined

  _sameTickStatsCheckThresholds: (key) ->
    stats = JustdoCoreHelpers._getSameTickStatsObject()

    if JustdoCoreHelpers.allow_break_if_threshold_reached
      if not (threshold_def = JustdoCoreHelpers._getSameTickStatsThresholdDefForKey(key))?
        # No threshold for key
        return

      if (break_type = threshold_def.break_if_threshold_reached)?
        val = stats[key]
        if _.isFunction threshold_def.threshold
          message = threshold_def.threshold(val)
        else
          if (val >= threshold_def.threshold)
            message = threshold_def.message(val, key)

        if not message?
          return

        if break_type == "once"
          once_key = "same-tick-stats-once-threshold-reported::" + key

          if JustdoCoreHelpers.sameTickCacheExists(once_key)
            return

          JustdoCoreHelpers.sameTickCacheSet(once_key, true)

        JustdoCoreHelpers.reportSameTickStatsOptimizationIssue("[THRESHOLD BREAK] " + message + " (#{key})")
        debugger

    return

  sameTickStatsGetVal: (key) ->
    stats = JustdoCoreHelpers._getSameTickStatsObject()

    return stats[key]

  sameTickStatsSetVal: (key, val) ->
    stats = JustdoCoreHelpers._getSameTickStatsObject()

    stats[key] = val

    JustdoCoreHelpers._sameTickStatsCheckThresholds(key)

    return

  sameTickStatsInc: (key, val) ->
    stats = JustdoCoreHelpers._getSameTickStatsObject()

    if not stats[key]?
      stats[key] = 0

    stats[key] += val

    JustdoCoreHelpers._sameTickStatsCheckThresholds(key)

    return

  sameTickStatsPushToArray: (key, val) ->
    stats = JustdoCoreHelpers._getSameTickStatsObject()

    if not _.isArray(stats[key])
      stats[key] = []
    
    stats[key].push val

    return

  sameTickStatsAddToDict: (key, dict_key, dict_val) ->
    stats = JustdoCoreHelpers._getSameTickStatsObject()

    if typeof stats[key] != "object"
      stats[key] = {}
    
    stats[key][dict_key] = dict_val

    return

JustdoCoreHelpers.stats_thresholds = thresholds