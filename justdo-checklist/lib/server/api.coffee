_.extend JustdoChecklist.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    APP.executeAfterAppLibCode ->
      APP.tasks_changelog_manager.setupPseudoCustomFieldTrackedBySimpleTasksFieldsChangesTracker("p:checklist:is_checked", "Checked")
      return

    return

    return