_.extend JustdoProjectConfigTicketsQueues.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()

    return