inspector = Npm.require "inspector"
{performance} = Npm.require "perf_hooks"

# Global profiling state
active_profiling_session = null

# log obj used in startMeteorMethodProfiling
meteor_method_logs = []
meteor_methods_profiling_active = false

# Original functions we override in startMeteorMethodProfiling
originalMeteorMethods = Meteor.methods
original_meteor_method_handlers_map = {}
original_mongo_methods_map = {}

requireUserIsSiteAdmin = (user_id) ->
  if not APP.justdo_site_admins?
    throw new Meteor.Error "site-admin-required"
  
  APP.justdo_site_admins.requireUserIsSiteAdmin(user_id)
  return

_.extend JustdoHelpers,
  startV8Profiling: ->
    if not APP.justdo_site_admins?.isCurrentUserSiteAdmin()
      throw new Meteor.Error "site-admin-required"
    promise = new Promise (resolve, reject) ->
      if active_profiling_session?
        return reject new Meteor.Error "not-supported", "V8 profiling session already active"

      active_profiling_session = new inspector.Session()
      active_profiling_session.connect()
      
      # Enable the profiler
      active_profiling_session.post 'Profiler.enable', (err) =>
        if err
          console.error "Failed to enable V8 profiler:", err
          return reject err
        
        # Start profiling
        active_profiling_session.post 'Profiler.start', (err) =>
          if err
            console.error "Failed to start V8 profiler:", err
            return reject err
          
          console.log "V8 profiling started"
          resolve()
        
    return promise
  
  stopV8Profiling: ->
    promise = new Promise (resolve, reject) ->
      if not active_profiling_session?
        return reject new Meteor.Error "not-supported", "No active V8 profiling session found"
    
      # Stop profiling and get the profile
      active_profiling_session.post 'Profiler.stop', (err, {profile}) =>
        if err
          console.error "Failed to stop V8 profiler:", err
          reject err
        else
          resolve profile
        
        # Disable profiler and disconnect
        active_profiling_session.post 'Profiler.disable', =>
          active_profiling_session.disconnect()
          
        active_profiling_session = null

      return
        
    return promise

  startMeteorMethodProfiling: ->
    if meteor_methods_profiling_active
      throw new Meteor.Error "not-supported", "Meteor method profiling already active"
    
    meteor_methods_profiling_active = true

    wrapMeteorMethodWithBenchmark = (name, func) ->
      return (args...) ->
        fiber = JustdoHelpers.getCurrentFiber()
        
        fiber.justdo_benchmark =
          fiber_id: JustdoHelpers.getFiberId()
          method_name: name
          method_args: args
          start_ts: performance.now()
          mongo_calls: []

        result = await func.apply @, args

        fiber.justdo_benchmark.end_ts = performance.now()
        fiber.justdo_benchmark.duration = fiber.justdo_benchmark.end_ts - fiber.justdo_benchmark.start_ts

        fiber.justdo_benchmark.mongo_calls_duration = _.reduce fiber.justdo_benchmark.mongo_calls, (acc, log_obj) ->
          acc + log_obj.duration
        , 0
        fiber.justdo_benchmark.mongo_calls_count = fiber.justdo_benchmark.mongo_calls.length
        meteor_method_logs.push fiber.justdo_benchmark
        return result
    
    wrapMongoMethodWithBenchmark = (name, func) ->
      return (args...) ->
        fiber = JustdoHelpers.getCurrentFiber()

        log_obj =
          method_name: name
          method_args: args
          collection_name: @_name
          
        if fiber?.justdo_benchmark?
          fiber.justdo_benchmark.mongo_calls.push log_obj
          log_obj.start_ts = performance.now()
        result = func.apply @, args

        if fiber?.justdo_benchmark?
          log_obj.end_ts = performance.now()
          log_obj.duration = log_obj.end_ts - log_obj.start_ts

        return result
    
    wrapMongoMethodWithBenchmarkAsync = (name, func) ->
      return (args...) ->
        fiber = JustdoHelpers.getCurrentFiber()

        log_obj =
          name: name
          args: args
          
        if fiber?.justdo_benchmark?
          fiber.justdo_benchmark.mongo_calls.push log_obj
          log_obj.start_ts = performance.now()

        result = await func.apply @, args

        if fiber?.justdo_benchmark?
          log_obj.end_ts = performance.now()
          log_obj.duration = log_obj.end_ts - log_obj.start_ts

          # method_name_without_async = name.replace "Async", ""
          # raw_collection = @rawCollection()
          # if _.isString args[0]
          #   args[0] = {_id: args[0]}
          # if method_name_without_async is "update"
          #   log_obj.explain = await raw_collection[method_name_without_async](args[0], args[1], _.extend({}, args[2], {explain: true}))
          # else
          #   log_obj.explain = await raw_collection[method_name_without_async](args...).explain()
    
        return result
      
    # Override mongo methods with benchmark
    mongo_methods_to_wrap = [
      "find"
      "findOne"
      "findOneAsync"
      "update"
      "updateAsync"
      "upsert"
      "upsertAsync"
      "remove"
      "removeAsync"
      "insert"
      "insertAsync"
      "count"
      "countAsync"
    ]
    for name in mongo_methods_to_wrap
      do (name) ->
        if (original_func = Mongo.Collection.prototype[name])?
          original_mongo_methods_map[name] = original_func
          if name.endsWith "Async"
            Mongo.Collection.prototype[name] = wrapMongoMethodWithBenchmarkAsync name, original_func
          else
            Mongo.Collection.prototype[name] = wrapMongoMethodWithBenchmark name, original_func
        return

    # Override registered Meteor methods with benchmark
    for name, func of Meteor.server.method_handlers
      do (name, func) ->
        original_meteor_method_handlers_map[name] = func
        Meteor.server.method_handlers[name] = wrapMeteorMethodWithBenchmark name, func
        return

    # For methods registered later, wrap them with the same setup
    Meteor.methods = (method_obj) ->
      method_obj_with_timer = {}
      for name, func of method_obj
        method_obj_with_timer[name] = wrapMeteorMethodWithBenchmark name, func
      
      originalMeteorMethods method_obj_with_timer
      
      return

    return

  stopMeteorMethodProfiling: ->
    if not meteor_methods_profiling_active
      throw new Meteor.Error "not-supported", "Meteor method profiling not active"
    

    for name, func of original_mongo_methods_map
      Mongo.Collection.prototype[name] = func

    for name, func of original_meteor_method_handlers_map
      Meteor.server.method_handlers[name] = func

    Meteor.methods = originalMeteorMethods

    ret = Array.from meteor_method_logs
    meteor_method_logs = []
    
    meteor_methods_profiling_active = false

    return ret

  
Meteor.methods 
  "JDHelpersProfilerStartV8Profiling": ->
    requireUserIsSiteAdmin @userId
    return JustdoHelpers.startV8Profiling()
  
  "JDHelpersProfilerStopV8Profiling": ->
    requireUserIsSiteAdmin @userId
    return JustdoHelpers.stopV8Profiling()
  
  "JDHelpersProfilerStartMeteorMethodProfiling": ->
    requireUserIsSiteAdmin @userId
    return JustdoHelpers.startMeteorMethodProfiling()
  
  "JDHelpersProfilerStopMeteorMethodProfiling": ->
    requireUserIsSiteAdmin @userId
    return JustdoHelpers.stopMeteorMethodProfiling()