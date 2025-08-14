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
    runBarriers = (barrier_ids) ->
      barriers = new Barriers()
      cb_before_barrier_executed = false
      cb_after_barrier_executed = false
      
      console.log "ℹ️ Registering cb before barrier `#{barrier_ids}` is resolved"
      barriers.runCbAfterBarriers barrier_ids, ->
        cb_before_barrier_executed = true
        console.log "✅ cb registered before barrier `#{barrier_ids}` is executed"
        return

      console.log "ℹ️ Marking barrier as resolved"
      barrier_ids_copy = null
      if _.isString barrier_ids
        barrier_ids_copy = [barrier_ids]
      else
        barrier_ids_copy = barrier_ids

      for barrier_id in barrier_ids_copy
        barriers.markBarrierAsResolved barrier_id

      Meteor.setTimeout =>
        if not cb_after_barrier_executed
          console.log "❌ cb after barrier `#{barrier_ids}` is not executed"
        return
      , barriers.missing_barrier_timeout + 1
      
      console.log "ℹ️ Registering cb after barrier `#{barrier_ids}` is resolved"
      barriers.runCbAfterBarriers barrier_ids, ->
        cb_after_barrier_executed = true
        console.log "✅ cb registered after barrier `#{barrier_ids}` is executed"
        return
      
      return

    console.log "💡 Testing single barrier"
    barrier_id = "test"
    runBarriers barrier_id

    console.log "💡 Testing multiple barriers"
    barrier_ids = ["test1", "test2", "test3"]
    runBarriers barrier_ids

    return