clear_job = null
cache = {}

JustdoHelpers.report_all_stats = false
JustdoHelpers.allow_break_if_threshold_reached = false
if JustdoHelpers.isPocPermittedDomainsOrBeta()
  JustdoHelpers.report_all_stats = true
  JustdoHelpers.allow_break_if_threshold_reached = true

stats_key = "__stats"

pre_clean_procedures = []

_.extend JustdoHelpers,
  sameTickCacheExists: (key) ->
    return key of cache

  sameTickCacheGet: (key) ->
    return cache[key]

  sameTickCacheSet: (key, val) ->
    if not clear_job?
      clear_setupped_time = new Date()
      clear_job = setTimeout ->
        JustdoHelpers.sameTickStatsInc("same-tick-cache-clear-time", (new Date()) - clear_setupped_time)

        for proc in pre_clean_procedures
          proc(cache)

        cache = {}
        clear_job = null
      , 0

    return cache[key] = val

  getTickUid: ->
    if (tick_uid = @sameTickCacheGet("__tick_id"))?
      return tick_uid

    return @sameTickCacheSet("__tick_id", Random.id())

  generateSameTickCachedProcedure: (key, proc) ->
    # We use Tracker.nonreactive to avoid quirks where sometimes there are
    # reactive resources and sometimes there aren't
    return (args...) =>
      current_key = key # to avoid affecting the closure key
      if args.length > 0
        current_key = key + "::" + args.join(":")

      return if @sameTickCacheExists(current_key) then @sameTickCacheGet(current_key) else @sameTickCacheSet(current_key, Tracker.nonreactive -> proc.call(this, ...args))

  registerSameTickCachePreClearProcedure: (fn) ->
    pre_clean_procedures.push(fn)

    return

thresholds =
  # Example:
  # 
  # "ejson-clone":
  #   threshold_type: "regular" / "prefix" # if unset defaults to "regular"
  #                                       # For regular we expect a full stat-key cache
  #                                       # For prefix we trim everything after the ::
  #                                       # Note that message will be called with both message(val, key) ->
  #                                       # so it can be customized for the specific key that triggered it
  #   threshold: 50
  #   message: (val) -> "There were #{val} EJSON.clone calls in the same tick"
  #   break_if_threshold_reached: "once" # Set to "once" / "always" or use undefined to avoid break.
  #                                      # break will happen only if JustdoHelpers.allow_break_if_threshold_reached is true

  "ejson-clone":
    threshold_type: "regular"
    threshold: 50
    message: (val) -> "There were #{val} EJSON.clone calls in the same tick"
    break_if_threshold_reached: "once" # Set to "once" / "always" or use undefined to avoid

  "ejson-parse":
    threshold_type: "regular"
    threshold: 10
    message: (val) -> "There were #{val} EJSON.parse calls in the same tick"
    break_if_threshold_reached: undefined

  "minimongo-find":
    threshold_type: "regular"
    threshold: 10
    message: (val) -> "There were #{val} minimongo finds in the same tick"
    break_if_threshold_reached: undefined

  "same-tick-cache-clear-time":
    threshold_type: "regular"
    threshold: 200
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
    threshold: 10
    message: (val, key) ->
      collection_name = JustdoHelpers._getSameTickStatsTrimmedVal(key)?.split(":")?[1]

      ret = "More than #{val} observers were set in the same tick"
      if collection_name?
        ret += " on collection: #{collection_name}"
      
      return ret
    break_if_threshold_reached: "once"

  "minimongo-reactive-observer-total-running":
    threshold_type: "prefix"
    threshold: 10
    message: (val, key) ->
      collection_name = JustdoHelpers._getSameTickStatsTrimmedVal(key)?.split(":")?[1]

      return "More than #{val} reactive observers are running on collection: #{collection_name}"
    break_if_threshold_reached: undefined

JustdoHelpers.registerSameTickCachePreClearProcedure ->
  stats = JustdoHelpers.sameTickCacheGet(stats_key)

  if not stats?
    return

  for stat_key, val of stats
    if (threshold_def = thresholds[stat_key])? or (threshold_def = thresholds[JustdoHelpers._getSameTickStatsTrimmedKey(stat_key)])?
      if val >= threshold_def.threshold
        JustdoHelpers.reportSameTickStatsOptimizationIssue(threshold_def.message(val, stat_key))

  if JustdoHelpers.report_all_stats
    console.log "STATS", stats

  return

_.extend JustdoHelpers,
  reportOptimizationIssue: (message, data) ->
    console.error "[OPTIMIZATION ISSUE] #{message}", data
    return

  reportSameTickStatsOptimizationIssue: (message) ->
    JustdoHelpers.reportOptimizationIssue(message, JustdoHelpers.sameTickCacheGet(stats_key))
    return

  _getSameTickStatsObject: ->
    stats = JustdoHelpers.sameTickCacheGet(stats_key)

    if typeof stats != "object"
      stats =
        tick_id: JustdoHelpers.getTickUid()

      JustdoHelpers.sameTickCacheSet(stats_key, stats)

    return stats

  _getSameTickStatsTrimmedKey: (key) ->
    return key.substr(0, key.indexOf("::"))

  _getSameTickStatsTrimmedVal: (key) ->
    return key.substr(key.indexOf("::") + 2)

  _getSameTickStatsThresholdDefForKey: (key) ->
    if (threshold_def = thresholds[key])?
      return threshold_def

    trimmed_key = JustdoHelpers._getSameTickStatsTrimmedKey(key)

    if thresholds[trimmed_key]?.threshold_type == "prefix"
      return thresholds[trimmed_key]

    return undefined

  _sameTickStatsCheckThresholds: (key) ->
    stats = JustdoHelpers._getSameTickStatsObject()

    if JustdoHelpers.allow_break_if_threshold_reached
      if not (threshold_def = JustdoHelpers._getSameTickStatsThresholdDefForKey(key))?
        # No threshold for key
        return

      if (break_type = threshold_def.break_if_threshold_reached)?
        if (stats[key] >= threshold_def.threshold)
          if break_type == "once"
            once_key = "same-tick-stats-once-threshold-reported" + key

            if JustdoHelpers.sameTickCacheExists(once_key)
              return

            JustdoHelpers.sameTickCacheSet(once_key, true)

          JustdoHelpers.reportSameTickStatsOptimizationIssue("[THRESHOLD BREAK] " + threshold_def.message(stats[key], key))
          debugger

    return

  sameTickStatsSetVal: (key, val) ->
    stats = JustdoHelpers._getSameTickStatsObject()

    stats[key] = val

    JustdoHelpers._sameTickStatsCheckThresholds(key)

    return

  sameTickStatsInc: (key, val) ->
    stats = JustdoHelpers._getSameTickStatsObject()

    if not stats[key]?
      stats[key] = 0

    stats[key] += val

    JustdoHelpers._sameTickStatsCheckThresholds(key)

    return

  sameTickStatsPushToArray: (key, val) ->
    stats = JustdoHelpers._getSameTickStatsObject()

    if not _.isArray(stats[key])
      stats[key] = []
    
    stats[key].push val

    return

  sameTickStatsAddToDict: (key, dict_key, dict_val) ->
    stats = JustdoHelpers._getSameTickStatsObject()

    if typeof stats[key] != "object"
      stats[key] = {}
    
    stats[key][dict_key] = dict_val

    return

JustdoHelpers.stats_thresholds = thresholds
