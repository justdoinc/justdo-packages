# FUNCTIONS
makeTasksDraggable = ->
  $(".kanban-task").draggable
    helper: "clone"
    start: (event, ui) ->
      $(ui.helper).width($(event.target).width())
  return

activeTaskId = -> JD.activeItem({_id: 1})?._id

# ON CREATED
Template.project_pane_kanban.onCreated ->
  tpl = @

  tpl.kanban_task_id_rv = new ReactiveVar(activeTaskId()) # Attempt to init to the current active task if any
  tpl.active_board_field_id_rv = new ReactiveVar(null)
  tpl.current_board_state_rv = new ReactiveVar(null)
  @autorun =>
    if not (current_kanban_task_id = tpl.kanban_task_id_rv.get())? and (active_task_id = activeTaskId())?
      # If we don't have a kanban task id set, as soon as the user hits a task
      # we set it as the kanban's task id
      current_kanban_task_id = active_task_id

      tpl.kanban_task_id_rv.set(active_task_id)

    active_board_field_id = APP.justdo_kanban.getTaskKanbanViewStateActiveFieldId(current_kanban_task_id)
    tpl.active_board_field_id_rv.set(active_board_field_id)

    current_board_state_rv = APP.justdo_kanban.getTaskKanbanViewStateBoardState(current_kanban_task_id, active_board_field_id)
    tpl.current_board_state_rv.set(current_board_state_rv)

    return

  tpl.getKanbanTaskDoc = -> APP.collections.Tasks.findOne(tpl.kanban_task_id_rv.get())
  tpl.getCurrentBoardStateVisibleBoards = -> tpl.current_board_state_rv.get()?.visible_boards
  tpl.getCurrentBoardStateVisibleBoardsBoard = (board_id) ->
    visible_boards = tpl.getCurrentBoardStateVisibleBoards()

    return _.findWhere visible_boards, {board_value_id: board_id}
  tpl.setCurrentBoardStateValue = (key, value) -> APP.justdo_kanban.setTaskKanbanViewStateBoardStateValue(tpl.kanban_task_id_rv.get(), tpl.active_board_field_id_rv.get(), key, value)

  tpl.members_dropdown_search_input_state_rv = new ReactiveVar null

  tpl.kanban = new ReactiveVar null
  tpl.kanbanActiveBoardId = new ReactiveVar null

  # Tracker.autorun =>
  #   if (kanban_task_id = tpl.kanban_task_id_rv.get())?
  #     kanban = APP.justdo_kanban.kanbans_collection.findOne(kanban_task_id)
  #     if kanban?
  #       tpl.kanban.set kanban[Meteor.userId()]

  #     setTimeout ->
  #       # Make Kanban Sortable
  #       $(".kanban-boards").sortable
  #         items: ".kanban-board"
  #         helper: "clone"
  #         tolerance: "pointer"
  #         cancel: ".kanban-board-control, .kanban-task-control, .kanban-task-add"
  #         update: ( event, ui ) ->
  #           kanban_task_id = tpl.kanban_task_id_rv.get()
  #           visible_boards = []
  #           $(".kanban-board").each ->
  #             visible_boards.push Blaze.getData($(this)[0])

  #           # APP.justdo_kanban.updateKanban(kanban_task_id, "visible_boards", [])
  #           # APP.justdo_kanban.updateKanban(kanban_task_id, "visible_boards", visible_boards)
  #           return

  #       makeTasksDraggable()

  #       $(".kanban-board-content").droppable
  #         drop: (event, ui) ->
  #           boards_field_id = tpl.kanban.get().boards_field_id
  #           board_value_id = Blaze.getData(event.target).board_value_id
  #           task_id = Blaze.getData(ui.draggable[0])._id
  #           JD.collections.Tasks.update({_id: task_id}, {$set: {"#{boards_field_id}": board_value_id}})

  #           setTimeout ->
  #             makeTasksDraggable()
  #           , 500
  #           return

  #     , 1000


# HELPERS
Template.project_pane_kanban.helpers
  isSelectedTaskCollectionItem: -> APP.modules.project_page.getActiveGridItemType() == "default" # TESTED

  selectedTask: -> JD.activeItem() # TESTED

  activeTask: -> Template.instance().getKanbanTaskDoc() # TESTED

  projects: -> # TESTED
    project = APP.modules.project_page.project.get()
    if project?
      return APP.collections.Tasks.find({ "p:dp:is_project": true, project_id: project.id }, {sort: {"title": 1}}).fetch()

    return

  currentBoardStateVisibleBoards: -> Template.instance().getCurrentBoardStateVisibleBoards() # TESTED

  boardLabel: (board_value_id) -> # TESTED
    active_board_field_id = Template.instance().active_board_field_id_rv.get()

    return APP.modules.project_page.gridControl()?.getSchemaExtendedWithCustomFields()?[active_board_field_id]?.grid_values[board_value_id]?.txt

  boardIsVisible: (board_value_id) -> # TESTED
    for board in Template.instance().getCurrentBoardStateVisibleBoards()
      if board.board_value_id == board_value_id
        return true

    return false

  allActiveBoardFieldOptions: -> # TESTED
    active_board_field_id = Template.instance().active_board_field_id_rv.get()
    if (boards = APP.modules.project_page.gridControl()?.getSchemaExtendedWithCustomFields()?[active_board_field_id]?.grid_values)?
      return _.keys boards

    return []

  getBoardTasks: (board_value_id) -> # TESTED
    kanban_task_id = Template.instance().kanban_task_id_rv.get()
    active_board_field_id = Template.instance().active_board_field_id_rv.get()
    current_board_state = Template.instance().current_board_state_rv.get()

    if kanban_task_id? and (active_justdo_id = JD.activeJustdo({_id: 1})?._id)?
      parent_id = "parents." + kanban_task_id

      query = _.extend {}, current_board_state.query,
        project_id: active_justdo_id
        "#{parent_id}": {$exists: true}
        "#{active_board_field_id}": "#{board_value_id}"

      return APP.collections.Tasks.find(query, {sort: current_board_state.sort})

    return []

  memberFilter: -> # TESED
    current_board_state = Template.instance().current_board_state_rv.get()

    if _.isString(owner_id_query_val = current_board_state.query?.owner_id)
      return owner_id_query_val

    return null

  thisIsActiveMember: (user_id) -> # TESTED
    current_board_state = Template.instance().current_board_state_rv.get()

    if _.isString(owner_id_query_val = current_board_state.query?.owner_id)
      return owner_id_query_val == user_id

    return false

  boardCount: (board_value_id) -> # TESTED
    tpl = Template.instance()

    if (boards_field_id = tpl.active_board_field_id_rv.get())? and (current_kanban_task_id = tpl.kanban_task_id_rv.get())?
      tasks_count = APP.collections.Tasks.find({"parents.#{current_kanban_task_id}": {$exists: true}, "#{boards_field_id}": "#{board_value_id}"}).count()

      if tasks_count > 0
        return tasks_count

    return

  isLimitCrossed: ->
    tpl = Template.instance()

    value_id = @board_value_id

    if not (board = tpl.getCurrentBoardStateVisibleBoardsBoard(value_id))?
      return false

    if not (limit = board.limit)?
      return false

    if not (kanban_task_id = Template.instance().kanban_task_id_rv.get())?
      return false

    boards_field_id = tpl.active_board_field_id_rv.get()

    parent_id = "parents." + kanban_task_id

    count = JD.collections.Tasks.find({"#{parent_id}": {$exists: true}, "#{boards_field_id}": "#{value_id}"}).count()

    if count > limit
      return true

    return false

  taskPriorityColor: (priority) ->
    return JustdoColorGradient.getColorRgbString priority

  fields: ->
    fields = [{"field_id": "state"}]
    if JD.activeJustdo()?
      if JD.activeJustdo().custom_fields?
        for field in JD.activeJustdo().custom_fields
          if field.custom_field_type_id == "basic-select"
            fields.push {"field_id": field.field_id}
    return fields

  fieldLabel: (field_id) ->
    gc = APP.modules.project_page.gridControl()
    if gc?
      label = gc.getSchemaExtendedWithCustomFields()[field_id].label
      return label

  buttonFieldLabel: ->
    boards_field_id = Template.instance().active_board_field_id_rv.get()
    gc = APP.modules.project_page.gridControl()
    label = gc?.getSchemaExtendedWithCustomFields()[boards_field_id]?.label
    return label

  members: ->
    members_dropdown_search_input_state_rv = Template.instance().members_dropdown_search_input_state_rv.get()
    
    if (kanban_task_doc = Template.instance().getKanbanTaskDoc())?
      membersDocs = JustdoHelpers.filterUsersDocsArray(kanban_task_doc.users, members_dropdown_search_input_state_rv)
      return _.sortBy membersDocs, (member) -> JustdoHelpers.displayName(member)

  memberAvatar: (user_id) -> # TESTED
    user = Meteor.users.findOne({_id: user_id})
    if user?
      return user.profile.profile_pic

  memberName: (user_id) ->
    return JustdoHelpers.displayName(user_id)

  sortBy: ->
    kanban = Template.instance().kanban.get()
    if kanban?
      return Object.keys(kanban.sort)[0]

  sortByReverse: ->
    kanban = Template.instance().kanban.get()
    if kanban?
      if Object.values(kanban.sort)[0] < 0
        return true


# EVENTS
Template.project_pane_kanban.events
  "click .kanban-board-task-add-button": (e, tpl) ->
    $kanbanBoard = $(e.currentTarget).parents(".kanban-board")
    $KanbanBoardContent = $kanbanBoard.find(".kanban-board-content")
    $task_input = $kanbanBoard.find(".kanban-task-add-input")
    $task_input.focus()
    $KanbanBoardContent.animate { scrollTop: $task_input.offset().top }, 500
    return

  "click .js-kanban-selected-task": (e, tpl) -> # TESTED
    e.preventDefault()

    task_id = @_id
    tpl.kanban_task_id_rv.set task_id

    APP.modules.project_page.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(task_id)

    return

  "click .js-kanban-field-item": (e, tpl) ->
    e.preventDefault()
    kanban_task_id = tpl.kanban_task_id_rv.get()
    field_id = Blaze.getData(e.target).field_id
    APP.justdo_kanban.setTaskKanbanViewStateActiveFieldId(tpl.kanban_task_id_rv.get(), field_id)

    # Remove from here
    visible_boards = []

    gc = APP.modules.project_page.gridControl()
    board_values = gc?.getSchemaExtendedWithCustomFields()[field_id]?.grid_values

    for value in Object.keys(board_values)
      if value != ""
        visible_boards.push {board_value_id: value, limit: JustdoKanban.default_kanban_boards_limit}

    # APP.justdo_kanban.updateKanban(kanban_task_id, "boards_field_id", field_id)
    # APP.justdo_kanban.updateKanban(kanban_task_id, "visible_boards", visible_boards)


    return

  "click .kanban-task": (e, tpl) -> # TESTED
    APP.modules.project_page.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(@_id)

    return

  "keydown .kanban-task-add-input": (e, tpl) -> # NEED TO TEST SHAKE PART
    if e.which == 27 # Escape
      $(e.target).blur().val ""

      return

    if (e.which == 13 and not e.shiftKey) or e.which == 9 # Enter or Tab
      e.preventDefault()

      boards_field_id = tpl.active_board_field_id_rv.get()
      kanban_task_id = tpl.kanban_task_id_rv.get()
      board_value_id = @board_value_id
      board_limit = @limit

      if not (gc = APP.modules.project_page.gridControl())?
        console.error "Couldn't find grid control, this shouldn't happen."

        return

      board_label = gc?.getSchemaExtendedWithCustomFields()[boards_field_id].label
      task_title = $(e.target).val().trim()

      if task_title != ""
        gc?._grid_data?.addChild "/" + kanban_task_id + "/",
          project_id: JD.activeJustdo()._id
          title: task_title
          "#{boards_field_id}": board_value_id

        parent_id = "parents." + kanban_task_id
        tasks_count = APP.collections.Tasks.find({"#{parent_id}": {$exists: true}, "#{boards_field_id}": "#{board_value_id}"}).count()

        if board_limit > 0 and tasks_count.length > board_limit
          $kanban_board = $(e.currentTarget).parents(".kanban-board")
          $kanban_board.addClass "kanban-shake"
          setTimeout ->
            $kanban_board.removeClass "kanban-shake"
          , 1500

          JustdoSnackbar.show
            text: "'" + board_label + "' has a limit of " + board_limit + " Tasks"
            duration: 4000
            actionText: "Dismiss"
            onActionClick: =>
              JustdoSnackbar.close()
              return

        $(e.target).val ""

    return

  "click .kanban-task-remove": (e, tpl) ->
    $task = $(e.currentTarget).parents(".kanban-task")
    parent_task_id = tpl.kanban_task_id_rv.get()
    subtask_id = Blaze.getData(e.target)._id

    APP.modules.project_page.gridControl()?._grid_data?.removeParent "/#{parent_task_id}/#{subtask_id}/", (error) ->
      if error?
        $task.addClass "kanban-shake"
        setTimeout ->
          $task.removeClass "kanban-shake"
        , 1500
        JustdoSnackbar.show
          text: error.reason
          duration: 4000
          actionText: "Dismiss"
          onActionClick: =>
            JustdoSnackbar.close()
            return

      return

    return

  "click .kanban-sort-item": (e, tpl) ->
    e.preventDefault()
    kanban_task_id = tpl.kanban_task_id_rv.get()
    kanbanSortBy = $(e.currentTarget).attr "sortBy"
    kanbanSortByReverse = Object.values(tpl.kanban.get().sort)[0]
    if kanbanSortByReverse == -1
      # APP.justdo_kanban.updateKanban(kanban_task_id, "sort", {"#{kanbanSortBy}": 1})
    else
      # APP.justdo_kanban.updateKanban(kanban_task_id, "sort", {"#{kanbanSortBy}": -1})
    return

  "click .kanban-board-hide": (e, tpl) ->
    kanban_task_id = tpl.kanban_task_id_rv.get()
    board_value_id = Blaze.getData(e.target).board_value_id
    visible_boards = tpl.kanban.get().visible_boards

    visible_boards.forEach (boards, i) ->
      if boards.board_value_id == board_value_id
        visible_boards.splice(i, 1)

    # APP.justdo_kanban.updateKanban(kanban_task_id, "visible_boards", visible_boards)
    return

  "click .kanban-board-edit": (e, tpl) ->
    tpl.kanbanActiveBoardId.set Blaze.getData(e.target).board_value_id
    limit = Blaze.getData(e.target).limit
    if limit > 0
      $(".kanban-board-limit-input").val limit
    return

  "click .kanban-limit-save": (e, tpl) ->
    $kanban_limit_input = $(".kanban-board-limit-input")
    kanban_task_id = tpl.kanban_task_id_rv.get()
    board_id = tpl.kanbanActiveBoardId.get()
    limit_val = parseInt($kanban_limit_input.val())
    visible_boards = tpl.kanban.get().visible_boards

    if limit_val > 0
      visible_boards.forEach (boards, i) ->
        if boards.board_value_id == board_id
          visible_boards[i].limit = limit_val

      # APP.justdo_kanban.updateKanban(kanban_task_id, "visible_boards", visible_boards)
      $("#kanban-board-settings").modal "hide"
    else
      $kanban_limit_input.addClass "kanban-shake"
      setTimeout ->
        $kanban_limit_input.removeClass "kanban-shake"
      , 1500
    return

  "click .kanban-board-add-item": (e, tpl) ->
    kanban_task_id = tpl.kanban_task_id_rv.get()
    board_id = Blaze.getData(e.target)
    kanban = tpl.kanban.get()
    board_is_visible = $(e.target).hasClass "visible"
    if kanban?
      visible_boards = kanban.visible_boards
      if board_is_visible
        visible_boards.forEach (board, i) ->
          if board.board_value_id == board_id
            visible_boards.splice(i, 1)
      else
        visible_boards.push ({board_value_id: board_id, limit: JustdoKanban.default_kanban_boards_limit})

      # APP.justdo_kanban.updateKanban(kanban_task_id, "visible_boards", visible_boards)
    return

  "keyup .kanban-member-selector-search": (e, tpl) -> # TESTED
    value = $(e.target).val().trim()

    if _.isEmpty value
      return tpl.members_dropdown_search_input_state_rv.set null

    tpl.members_dropdown_search_input_state_rv.set value

    return

  "click .kanban-filter-member-item": (e, tpl) -> # TESTED
    e.preventDefault()

    user_id = Blaze.getData(e.target)

    tpl.setCurrentBoardStateValue("query", {owner_id: user_id})

    return

  "click .kanban-clear-member-filter": (e, tpl) -> # TESTED
    e.preventDefault()

    tpl.setCurrentBoardStateValue("query", {})

    return

