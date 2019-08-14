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