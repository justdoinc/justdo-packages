_.extend JustdoKanban.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  setupCustomFeatureMaintainer: ->
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoKanban.project_custom_feature_id,
        installer: =>
          @setupProjectPaneTab()

          return

        destroyer: =>
          @destroyProjectPaneTab()

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  setupProjectPaneTab: ->
    APP.justdo_project_pane.registerTab
      tab_id: "kanban"
      order: 100
      tab_template: "project_pane_kanban"
      tab_label: "Kanban"

    return

  destroyProjectPaneTab: ->
    APP.justdo_project_pane.unregisterTab "kanban"

    return

  _storeTaskKanbanViewState: (task_id, kanban_view_state) ->
    @tasks_collection.update(task_id, {$set: {"#{JustdoKanban.user_task_kanban_view_state_field_id}": JSON.stringify(kanban_view_state)}})

    return

  _getStoredTaskKanbanViewState: (task_id) ->
    # Returned the parsed JSON stored for the task, null if no value stored, or in any other
    # case (incl. task not existing etc.)

    if _.isString(stored_json_value = @tasks_collection.findOne(task_id, {fields: {"#{JustdoKanban.user_task_kanban_view_state_field_id}": 1}})?[JustdoKanban.user_task_kanban_view_state_field_id])
      return JSON.parse(stored_json_value)

    return null

  getTaskKanbanViewState: (task_id) ->
    if (stored_kanban_view_state = @_getStoredTaskKanbanViewState(task_id))?
      return stored_kanban_view_state

    default_kanban_view_state =
      active_board_field_id: JustdoKanban.default_kanban_active_board_field_id

    return default_kanban_view_state

  #
  # Active field id setter/getter
  #
  getTaskKanbanViewStateActiveFieldId: (task_id) ->
    # Returns the board state stored in the task's kanban view state , or the default board state
    # if a board state value can't be determined from the storage (for whatever reason)

    if (kanban_view_state = @getTaskKanbanViewState(task_id))?
      if (current_active_board_field_id = kanban_view_state.active_board_field_id)?
        return current_active_board_field_id

    return JustdoKanban.default_kanban_active_board_field_id

  setTaskKanbanViewStateActiveFieldId: (task_id, board_field_id) ->
    current_kanban_view_state = @getTaskKanbanViewState(task_id)

    current_kanban_view_state.active_board_field_id = board_field_id

    @_storeTaskKanbanViewState(task_id, current_kanban_view_state)

    return

  #
  # Boards setter/getter
  #
  getTaskKanbanViewStateBoardState: (task_id, board_field_id) ->
    # Returns the board state stored in the task's kanban view state , or the default board state
    # if a board state value can't be determined from the storage (for whatever reason)

    if (kanban_view_state = @getTaskKanbanViewState(task_id))?
      if (current_board_state = kanban_view_state.field_boards?[board_field_id])?
        return current_board_state

    default_board =
      sort:
        priority: 1
      query: {}

    # A board can't be determined from the storage, come up with a default one
    if board_field_id == "state"
      # the default board for state is a special case.

      default_board.visible_boards = [
        { board_value_id: "pending", limit: JustdoKanban.default_kanban_boards_limit },
        { board_value_id: "in-progress", limit: JustdoKanban.default_kanban_boards_limit },
        { board_value_id: "done", limit: JustdoKanban.default_kanban_boards_limit },
        { board_value_id: "nil", limit: JustdoKanban.default_kanban_boards_limit }
      ]
    else
      gc = APP.modules.project_page.gridControl()

      if not (field_grid_values = gc?.getSchemaExtendedWithCustomFields()[board_field_id]?.grid_values)?
        # Can't get field details
        return null

      visible_boards = []
      for field_id, field_def of field_grid_values
        visible_boards.push {board_value_id: field_id, limit: JustdoKanban.default_kanban_boards_limit}

      default_board.visible_boards = visible_boards

    return default_board

  setTaskKanbanViewStateBoardStateValue: (task_id, board_field_id, key, value) ->
    if not (current_board_state = @getTaskKanbanViewStateBoardState(task_id, board_field_id))?
      # Unknown board
      @logger.error "Unknown board field id #{board_field_id} for task #{task_id}"

      return

    current_board_state[key] = value

    current_kanban_view_state = @getTaskKanbanViewState(task_id)

    Meteor._ensure(current_kanban_view_state, "field_boards")

    current_kanban_view_state.field_boards[board_field_id] = current_board_state

    @_storeTaskKanbanViewState(task_id, current_kanban_view_state)

    return
