clear_job = null
cache = {}

_.extend JustdoHelpers,
  sameTickCacheExists: (key) ->
    return key of cache

  sameTickCacheGet: (key) ->
    return cache[key]

  sameTickCacheSet: (key, val) ->
    if not clear_job?
      clear_job = setTimeout ->
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