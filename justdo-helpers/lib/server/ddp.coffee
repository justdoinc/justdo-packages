tick_object = null

_.extend JustdoHelpers,
  currentDdpInvocation: ->
    # DPP._CurrentInvocation is an undocumentad API that provides access
    # to the this of the currently invoked method
    # Discovered thanks to https://github.com/peerlibrary/meteor-publish-context/blob/master/README.md

    return DDP._CurrentInvocation.get()

  currentDdpConnection: ->
    # DPP._CurrentInvocation is an undocumentad API that provides access
    # to the this of the currently invoked method
    # Discovered thanks to https://github.com/peerlibrary/meteor-publish-context/blob/master/README.md

    return @currentDdpInvocation()?.connection

  getTickObject: ->
    # Read docs for @getDdpConnectionObjectOrTickObject() to understand (one of the) usecases
    # for which we use @getTickObject()
    if tick_object?
      return tick_object

    tick_object = {}

    process.nextTick ->
      tick_object = null

      return

    return tick_object

  getDdpConnectionObjectOrTickObject: ->
    # In many situations, the @currentDdpConnection() is used to get an object that is
    # used as a connection-specific memory space.
    #
    # Operations that need such a memory space, should have a fallback for case they are
    # invoked outside of a DDP call.
    #
    # We use the way the JS events loop is working, to create a safe tick-specific memory
    # space, to be used as such a fallback. This is done in the @getTickObject() .

    if (conn = JustdoHelpers.currentDdpConnection())?
      return conn

    return @getTickObject()