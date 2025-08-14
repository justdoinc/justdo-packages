BarriersOptionsSchema = new SimpleSchema
  missing_hook_timeout:
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

  @missing_hook_timeout = options.missing_hook_timeout
  
  @barriers_registry = {}
  
  return @

_.extend Barriers.prototype,
  _ensureHookDepnendenciesDefined: (barrier_ids) ->
    # Receives hooks_ids (can be a string for single). Returns array of promises, same order
    # Note: array is returned also for the string input.
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
        
        # Create a promise that exposes the resolve and reject functions
        @barriers_registry[barrier_id].promise = new Promise (resolve, reject) =>
          @barriers_registry[barrier_id].resolve = resolve
          @barriers_registry[barrier_id].reject = reject
          return

      return_promises.push @barriers_registry[barrier_id].promise
    
    return return_promises

  runCbAfterBarriers: (barrier_ids, cb) ->
    # This callback is guarnteed to be called after all the dependecies are marked as completed
    # or if MISSING_HOOK_TIMEOUT elapsed.

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

    Meteor.setTimeout ->
      if not cb_executed
        console.error "Barriers timeout after #{@missing_hook_timeout}ms. Running cb."
        runCb()
      return
    , @missing_hook_timeout

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