_.extend JustdoKanban.prototype,
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

    return

  performInstallProcedures: (project_doc, user_id) ->
    # Called when plugin installed for project project_doc._id
    return

  performUninstallProcedures: (project_doc, user_id) ->
    # Called when plugin uninstalled from project project_doc._id

    # Note, isn't called on project removal

    return

  createKanban: (task_id, user_id) ->
    kanban = @kanbans_collection.findOne(task_id)
    kanban_default = {
      "boards_field_id": "state"
      "sort": {priority: 1}
      "query": {}
      "visible_boards": [
        { "board_value_id": "pending", "limit": JustdoKanban.default_kanban_boards_limit },
        { "board_value_id": "in-progress", "limit": JustdoKanban.default_kanban_boards_limit },
        { "board_value_id": "done", "limit": JustdoKanban.default_kanban_boards_limit },
        { "board_value_id": "will-not-do", "limit": JustdoKanban.default_kanban_boards_limit },
        { "board_value_id": "on-hold", "limit": JustdoKanban.default_kanban_boards_limit },
        { "board_value_id": "duplicate", "limit": JustdoKanban.default_kanban_boards_limit },
        { "board_value_id": "nil", "limit": JustdoKanban.default_kanban_boards_limit }
      ]
    }

    if kanban?
      if not kanban[user_id]?
        @kanbans_collection.update(task_id, {$set: {"#{user_id}": kanban_default}})
    else
      kanban = {"_id": task_id, "#{user_id}": kanban_default }
      @kanbans_collection.insert kanban
    return

  updateKanban: (task_id, key, val, user_id) ->
    @kanbans_collection.update(task_id, {$set: {"#{user_id}.#{key}": val}})
    return
