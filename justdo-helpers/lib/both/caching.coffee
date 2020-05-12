clearJob = null
cache = {}

_.extend JustdoHelpers,
  sameTickCacheExists: (key) ->
    return key of cache

  sameTickCacheGet: (key) ->
    return cache[key]

  sameTickCacheSet: (key, val) ->
    if not clearJob?
      clearJob = Meteor.defer ->
        cache = {}

    return cache[key] = val

  getTickUid: ->
    if (tick_uid = @sameTickCacheGet("__tick_id"))?
      return tick_uid

    return @sameTickCacheSet("__tick_id", Random.id())