_.extend JustdoFiles.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerTaskPaneSection()

    return