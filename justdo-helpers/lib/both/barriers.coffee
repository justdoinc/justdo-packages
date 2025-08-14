BarriersOptionsSchema = new SimpleSchema
  missing_barrier_timeout:
    type: Number
    optional: true
    defaultValue: 2000
  
Barriers = (options={}) ->
  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      BarriersOptionsSchema,
      options,
      {throw_on_error: true}
    )
  options = cleaned_val

  @missing_barrier_timeout = options.missing_barrier_timeout
  
  @barriers_registry = {}
  
  return @

_.extend Barriers.prototype,
  _ensureHookDepnendenciesDefined: (barrier_ids) ->
    # Receives barrier_ids (can be a string for single). 
    # Returns an array of promises in the same order as barrier_ids.

    if _.isString barrier_ids
      barrier_ids = [barrier_ids]
    
    return_promises = []
    
    for barrier_id in barrier_ids
      if not @barriers_registry[barrier_id]?
        # Could've shortened this block, but it explains the structure of the object better
        @barriers_registry[barrier_id] = 
          promise: null
          resolve: null
          reject: null
        
        # Create a promise that exposes the resolve and reject functions under @barriers_registry[barrier_id]
        @barriers_registry[barrier_id].promise = new Promise (resolve, reject) =>
          @barriers_registry[barrier_id].resolve = resolve
          @barriers_registry[barrier_id].reject = reject
          return

      return_promises.push @barriers_registry[barrier_id].promise
    
    return return_promises

  runCbAfterBarriers: (barrier_ids, cb) ->
    # The `cb` is guarnteed to be called after all the dependecies are marked as resolved or if @missing_barrier_timeout elapsed.

    cb_executed = false
    runCb = =>
      if cb_executed
        return

      cb()
      cb_executed = true
      return

    barriers_promises = @_ensureHookDepnendenciesDefined barrier_ids
    Promise.all barriers_promises
      .then =>
        runCb()
        return
      .catch (err) =>
        console.error err
        return

    Meteor.setTimeout =>
      if not cb_executed
        console.error "Barriers timeout after #{@missing_barrier_timeout}ms. Running cb."
        runCb()
      return
    , @missing_barrier_timeout

    return

  markBarrierAsResolved: (barrier_id) ->
    if not @barriers_registry[barrier_id]?
      return
    
    @barriers_registry[barrier_id].resolve()
    return
  
  markBarrierAsRejected: (barrier_id) ->
    if not @barriers_registry[barrier_id]?
      return
    
    @barriers_registry[barrier_id].reject()
    return


_.extend JustdoHelpers,
  Barriers: Barriers
  hooks_barriers: new Barriers()

  testBarriers: ->
    barrier_timeout = 1000

    sleepUntilTimeoutPlusOneSecond = ->
      promise = new Promise (resolve) =>
        Meteor.setTimeout =>
          resolve()
        , barrier_timeout + 1000
      return promise

    runBarriersCb = (barrier_ids, options) ->
      default_options = 
        barrier_ids_to_exclude: null
        cb_count: 1
      options = _.extend default_options, options

      {barrier_ids_to_exclude, cb_count} = options

      barriers = new Barriers({missing_barrier_timeout: barrier_timeout})
      cb_before_barrier_executed = false
      cb_after_barrier_executed = false
      
      for i in [1..cb_count]
        do (i) =>
          console.log "ℹ️ Registering cb#{i} before barrier `#{barrier_ids}` is resolved"
          barriers.runCbAfterBarriers barrier_ids, ->
            cb_before_barrier_executed = true
            console.log "✅ cb#{i} registered before barrier `#{barrier_ids}` is executed"
            return

      console.log "ℹ️ Marking barrier as resolved"
      barrier_ids_copy = null
      # Clone the barrier_ids array to avoid mutating the original array
      if _.isString barrier_ids
        barrier_ids_copy = [barrier_ids]
      else
        barrier_ids_copy = barrier_ids
      # Exclude the barrier_ids_to_exclude from the barrier_ids_copy
      if barrier_ids_to_exclude?
        if _.isString barrier_ids_to_exclude
          barrier_ids_to_exclude = [barrier_ids_to_exclude]

        barrier_ids_copy = _.without barrier_ids_copy, ...barrier_ids_to_exclude

      for barrier_id in barrier_ids_copy
        barriers.markBarrierAsResolved barrier_id

      # Set a timeout to check if the cbs are executed after the barrier is resolved or timed out
      Meteor.setTimeout =>
        if not cb_before_barrier_executed
          console.log "❌ cb before barrier `#{barrier_ids}` is not executed"

        if not cb_after_barrier_executed
          console.log "❌ cb after barrier `#{barrier_ids}` is not executed"

        return
      , barriers.missing_barrier_timeout + 1000
      
      for j in [1..cb_count]
        do (j) =>
          console.log "ℹ️ Registering cb#{j} after barrier `#{barrier_ids}` is resolved"
          barriers.runCbAfterBarriers barrier_ids, ->
            cb_after_barrier_executed = true
            console.log "✅ cb#{j} registered after barrier `#{barrier_ids}` is executed"
          return
      
      await sleepUntilTimeoutPlusOneSecond()
      return

    # Single barrier with single cb. Should pass
    barrier_id = "single_barrier_single_cb"
    console.log "\n💡 Testing single barrier with single cb `#{barrier_id}` - Should pass"
    await runBarriersCb barrier_id

    # Multiple barriers with single cb. Should pass
    barrier_id_prefix = "multiple_barriers_single_cb"
    barrier_ids = ["#{barrier_id_prefix}_1", "#{barrier_id_prefix}_2", "#{barrier_id_prefix}_3"]
    console.log "\n💡 Testing multiple barriers with single cb `#{barrier_id_prefix}` - Should pass"
    await runBarriersCb barrier_ids

    # Single barrier that never resolve with single cb. Should pass with timeout
    barrier_id = "single_barrier_never_resolved_single_cb"
    console.log "\n💡 Testing single barriers that never resolve with single cb `#{barrier_id}` - Should pass with timeout"
    await runBarriersCb barrier_id, {barrier_ids_to_exclude: barrier_id}

    # Multiple barriers that partially resolve with single cb. Should pass with timeout
    barrier_id_prefix = "multiple_barriers_partially_resolved_single_cb"
    barrier_ids = ["#{barrier_id_prefix}_1", "#{barrier_id_prefix}_2", "#{barrier_id_prefix}_3"]
    console.log "\n💡 Testing multiple barriers that partially resolve with single cb `#{barrier_id_prefix}` - Should pass with timeout"
    await runBarriersCb barrier_ids, {barrier_ids_to_exclude: barrier_ids[0]}

    # Single barrier with two cbs. Should pass
    barrier_id = "single_barrier_2_cb"
    console.log "\n💡 Testing single barrier with two cbs `#{barrier_id}` - Should pass"
    await runBarriersCb barrier_id, {cb_count: 2}

    # Multiple barriers with two cbs. Should pass
    barrier_id_prefix = "multiple_barriers_2_cb"
    barrier_ids = ["#{barrier_id_prefix}_1", "#{barrier_id_prefix}_2", "#{barrier_id_prefix}_3"]
    console.log "\n💡 Testing multiple barriers with two cbs `#{barrier_id_prefix}` - Should pass"
    await runBarriersCb barrier_ids, {cb_count: 2}

    # Single barrier that never resolve with two cbs. Should pass with timeout
    barrier_id = "single_barrier_never_resolved_2_cb"
    console.log "\n💡 Testing single barriers that never resolve with two cbs `#{barrier_id}` - Should pass with timeout"
    await runBarriersCb barrier_id, {barrier_ids_to_exclude: barrier_id, cb_count: 2}

    # Multiple barriers that partially resolve with two cbs. Should pass with timeout
    barrier_id_prefix = "multiple_barriers_partially_resolved_2_cb"
    barrier_ids = ["#{barrier_id_prefix}_1", "#{barrier_id_prefix}_2", "#{barrier_id_prefix}_3"]
    console.log "\n💡 Testing multiple barriers that partially resolve with two cbs `#{barrier_id_prefix}` - Should pass with timeout"
    await runBarriersCb barrier_ids, {barrier_ids_to_exclude: barrier_ids[0], cb_count: 2}

    return