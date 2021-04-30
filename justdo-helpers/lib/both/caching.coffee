clear_job = null
cache = {}

report_all_stats = false
allow_break_if_threshold_reached = false
if JustdoHelpers.isPocPermittedDomainsOrBeta()
  report_all_stats = true
  allow_break_if_threshold_reached = true

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
  #   threshold: 50
  #   message: (val) -> "There were #{val} EJSON.clone calls in the same tick"
  #   break_if_threshold_reached: "once" # Set to "once" / "always" or use undefined to avoid break.
  #                                      # break will happen only if allow_break_if_threshold_reached is true

  "ejson-clone":
    threshold: 50
    message: (val) -> "There were #{val} EJSON.clone calls in the same tick"
    break_if_threshold_reached: "once" # Set to "once" / "always" or use undefined to avoid

  "ejson-parse": (val) ->
    threshold: 10
    message: (val) -> "There were #{val} EJSON.parse calls in the same tick"
    break_if_threshold_reached: undefined

  "minimongo-find": (val) ->
    threshold: 10
    message: (val) -> "There were #{val} minimongo finds in the same tick"
    break_if_threshold_reached: undefined

  "same-tick-cache-clear-time": (val) ->
    threshold: 200
    message: (val) -> "A tick took more than #{val} ms to execute" # "at least", because clear_setupped_time isn't set immediately when the tick start
    break_if_threshold_reached: undefined

  "minimongo-find-not-by-id-total-scanned-docs": (val) ->
    threshold: 1000
    message: (val) -> "More than #{val} minimongo documents scanned in the same tick"
    break_if_threshold_reached: undefined

  "minimongo-find-not-by-id-total-time-ms": (val) ->
    threshold: 100
    message: (val) -> "More than #{val} ms spent scanning minimongo documents"
    break_if_threshold_reached: undefined

  "minimongo-find-not-by-id-total-sort-time-ms": (val) ->
    threshold: 50
    message: (val) -> "More than #{val} ms spent sorting minimongo documents"
    break_if_threshold_reached: undefined

JustdoHelpers.registerSameTickCachePreClearProcedure ->
  stats = JustdoHelpers.sameTickCacheGet(stats_key)

  if not stats?
    return

  for threshold_key, threshold_def of thresholds
    if (val = stats[threshold_key])?
      if val >= threshold_def.threshold
        JustdoHelpers.reportSameTickStatsOptimizationIssue(threshold_def.message(val))

  if report_all_stats
    console.log "STATS", stats

  return

_.extend JustdoHelpers,
  reportOptimizationIssue: (message, data) ->
    console.error "[OPTIMIZATION ISSUE] #{message}", data
    return

  reportSameTickStatsOptimizationIssue: (message) ->
    JustdoHelpers.reportOptimizationIssue(message, JustdoHelpers.sameTickCacheGet(stats_key))
    return

  sameTickStatsInc: (key, val) ->
    stats = JustdoHelpers.sameTickCacheGet(stats_key)

    if typeof stats != "object"
      stats = {}
      JustdoHelpers.sameTickCacheSet(stats_key, stats)

    if not stats[key]?
      prev_val = 0
      stats[key] = 0
    else
      prev_val = stats[key]

    stats[key] += val

    if allow_break_if_threshold_reached
      if (threshold_def = thresholds[key])?
        if (break_type = threshold_def.break_if_threshold_reached)?
          if (break_type is "always" and stats[key] >= threshold_def.threshold) or (break_type is "once" and prev_val < threshold_def.threshold and stats[key] >= threshold_def.threshold)
            JustdoHelpers.reportSameTickStatsOptimizationIssue(threshold_def.message(stats[key]))

            debugger

    return

