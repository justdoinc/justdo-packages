_.extend JustdoNewProjectTemplates.prototype,
  _bothImmediateInit: ->
    @setupRouter()

    return

  _bothDeferredInit: ->
    if @destroyed
      return

    return
