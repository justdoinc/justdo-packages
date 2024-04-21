MiddlewaresQueueAsync = ->
  @middlewares = {}

  return @

_.extend MiddlewaresQueueAsync.prototype,
  set: (middleware_name, middleware) ->
    if not @middlewares[middleware_name]?
      @middlewares[middleware_name] = new Set()

    @middlewares[middleware_name].add middleware

    return

  unset: (middleware_name, middleware) ->
    if @middlewares[middleware_name]?
      @middlewares[middleware_name].delete middleware

    return

  run: (middleware_name, ...args) ->
    prom = Promise.resolve()

    if (handlers = @middlewares[middleware_name])?
      handlers.forEach (handler) ->
        prom = prom.then (result) ->
          if result == false # === false
            throw new Meteor.Error "middleware-blocked"

          return handler ...args

    return prom

MiddlewaresQueueSync = ->
  @middlewares = {}

  return @

_.extend MiddlewaresQueueSync.prototype,
  set: MiddlewaresQueueAsync.prototype.set
  
  unset: MiddlewaresQueueAsync.prototype.unset

  run: (middleware_name, ...args) ->
    if (handlers = @middlewares[middleware_name])?
      iterator = handlers.values()
      while (handler = iterator.next()) and not handler.done
        if handler.value(...args) == false
          return false
    
    return true

_.extend JustdoHelpers,
  generateMiddlewaresQueueAsync: ->
    return new MiddlewaresQueueAsync()
  
  generateMiddlewaresQueueSync: ->
    return new MiddlewaresQueueSync()
