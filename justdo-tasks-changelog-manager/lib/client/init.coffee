_.extend TasksChangelogManager.prototype,
  _immediateInit: ->
    @changelog_types_filtered_from_ui = new Set()
    @_setupCustomChangeTypeRegistrar()
    return

  _deferredInit: ->
    return