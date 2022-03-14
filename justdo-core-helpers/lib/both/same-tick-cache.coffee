clear_job = null
cache = {}

pre_clean_procedures = []

_.extend JustdoCoreHelpers,
  sameTickCachePurge: ->
    return cache = {}

  sameTickCacheExists: (key) ->
    return key of cache

  sameTickCacheGet: (key) ->
    return cache[key]

  sameTickCacheSet: (key, val) ->
    if not clear_job?
      clear_setupped_time = new Date()
      clear_job = setTimeout ->
        JustdoCoreHelpers.sameTickStatsInc("same-tick-cache-clear-time", (new Date()) - clear_setupped_time)

        for proc in pre_clean_procedures
          proc(cache)

        JustdoCoreHelpers.sameTickCachePurge()
        clear_job = null
      , 0

    return cache[key] = val

  sameTickCacheUnset: (key) ->
    delete cache[key]
    return

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
