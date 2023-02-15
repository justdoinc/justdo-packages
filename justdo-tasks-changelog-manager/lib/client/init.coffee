_.extend TasksChangelogManager.prototype,
  _immediateInit: ->
    @changelog_types_filtered_from_ui = new Set()
    return

  _deferredInit: ->
    return