# ON CREATED
Template.project_pane_kanban_board.onCreated ->
  @show_limit_control = new ReactiveVar false
  return

# ON RENDERED
Template.project_pane_kanban_board.onRendered ->
  tpl = @

  $(".kanban-board-dropdown").on "hidden.bs.dropdown", ->
    tpl.show_limit_control.set false
    return

  $(".kanban-boards").sortable
    items: ".kanban-board"
    tolerance: "pointer"
    cancel: ".kanban-board-control, .kanban-task-control, .kanban-task-add"
    deactivate: (event, ui) ->
      visible_boards = []
      $(".kanban-board").each ->
        data = Blaze.getData($(this).get(0))
        visible_boards.push { "board_value_id": data.board_value_id, "limit": data.limit}
        return

      $(".kanban-boards").sortable "cancel"
      APP.justdo_kanban.setTaskKanbanViewStateBoardStateValue(tpl.data.kanban_task_id_rv, tpl.data.active_board_field_id_rv, "visible_boards", visible_boards)
      return

  return

# HELPERS
Template.project_pane_kanban_board.helpers
  boardCount: ->
    if (boards_field_id = @active_board_field_id_rv)? and (current_kanban_task_id = @kanban_task_id_rv)?
      tasks_count = APP.collections.Tasks.find({"parents.#{current_kanban_task_id}": {$exists: true}, "#{boards_field_id}": "#{@board_value_id}" or {$exists: false}}).count()

      if tasks_count > 0
        return tasks_count
      else
        return 0

  boardLabel: ->
    label = APP.modules.project_page.gridControl()?.getSchemaExtendedWithCustomFields()?[@active_board_field_id_rv]?.grid_values[@board_value_id]?.txt
    if label == ""
      return "—"
    else
      return label

  getBoardTasks: ->
    if @kanban_task_id_rv? and (active_justdo_id = JD.activeJustdo({_id: 1})?._id)?
      parent_id = "parents." + @kanban_task_id_rv

      query = _.extend {}, @current_board_state_rv.query,
        project_id: active_justdo_id
        "#{parent_id}": {$exists: true}
        if @board_value_id == ""
          "#{@active_board_field_id_rv}": {$exists: false}
          "#{@active_board_field_id_rv}": null
        else
          "#{@active_board_field_id_rv}": "#{@board_value_id}"

      return APP.collections.Tasks.find(query, {sort: @current_board_state_rv.sort})

    return []

  showLimitControl: -> Template.instance().show_limit_control.get()

  isLimitCrossed: ->
    parent_id = "parents." + @kanban_task_id_rv
    count = JD.collections.Tasks.find({"#{parent_id}": {$exists: true}, "#{@active_board_field_id_rv}": "#{@board_value_id}" or {$exists: false}}).count()

    if count > @limit
      return true

    return false

# EVENTS
Template.project_pane_kanban_board.events
  "click .kanban-board-task-add-button": (e, tpl) ->
    $kanbanBoard = $(e.currentTarget).parents(".kanban-board")
    $KanbanBoardContent = $kanbanBoard.find(".kanban-board-content")
    $task_input = $kanbanBoard.find(".kanban-task-add-input")
    $task_input.focus()
    $KanbanBoardContent.animate { scrollTop: $task_input.offset().top }, 500
    return

  "click .kanban-board-edit": (e, tpl) ->
    e.stopPropagation()
    $dropdown = $(e.currentTarget).parents(".kanban-board-dropdown")
    tpl.show_limit_control.set true
    setTimeout ->
      $dropdown.find(".kanban-board-limit-input").focus()
    , 300

    return

  "click .kanban-board-limit-cancel": (e, tpl) ->
    e.stopPropagation()
    tpl.show_limit_control.set false
    return

  "click .kanban-board-limit-save": (e, tpl) ->
    $input = $(e.currentTarget).prev()
    limit = parseInt($input.val())

    if limit <= 0 or isNaN(limit)
      e.stopPropagation()
      $input.focus().addClass "kanban-shake"
      setTimeout -> $input.removeClass "kanban-shake", 1500
    else
      visible_boards = @current_board_state_rv.visible_boards
      board_value_id = @board_value_id

      for board, i in visible_boards
        if board.board_value_id == board_value_id
          visible_boards[i].limit = limit

      APP.justdo_kanban.setTaskKanbanViewStateBoardStateValue(@kanban_task_id_rv, @active_board_field_id_rv, "visible_boards", visible_boards)

      tpl.show_limit_control.set false
    return

  "keydown .kanban-board-dropdown": (e, tpl) ->
    if e.which == 27 # Escape
      $(e.currentTarget).find(".kanban-board-dropdown-icon").dropdown "hide"
      tpl.show_limit_control.set false

    if e.which == 13 # Enter
      $input = $(e.currentTarget).find(".kanban-board-limit-input")
      limit = parseInt($input.val())

      if limit <= 0 or isNaN(limit)
        e.stopPropagation()
        $input.focus().addClass "kanban-shake"
        setTimeout -> $input.removeClass "kanban-shake", 1500
      else
        visible_boards = @current_board_state_rv.visible_boards
        board_value_id = @board_value_id

        for board, i in visible_boards
          if board.board_value_id == board_value_id
            visible_boards[i].limit = limit

        APP.justdo_kanban.setTaskKanbanViewStateBoardStateValue(@kanban_task_id_rv, @active_board_field_id_rv, "visible_boards", visible_boards)

        $(e.currentTarget).find(".kanban-board-dropdown-icon").dropdown "hide"
        tpl.show_limit_control.set false

    return

  "keydown .kanban-task-add-input": (e, tpl) ->
    if e.which == 27 # Escape
      $(e.target).blur().val ""

      return

    if (e.which == 13 and not e.shiftKey) or e.which == 9 # Enter or Tab
      e.preventDefault()

      if not (gc = APP.modules.project_page.gridControl())?
        console.error "Couldn't find grid control, this shouldn't happen."
        return

      task_title = $(e.target).val().trim()

      if task_title != ""
        gc?._grid_data?.addChild "/" + @kanban_task_id_rv + "/",
          project_id: JD.activeJustdo({_id: 1})._id
          title: task_title
          "#{@active_board_field_id_rv}": @board_value_id

        parent_id = "parents." + @kanban_task_id_rv
        tasks_count = APP.collections.Tasks.find({"#{parent_id}": {$exists: true}, "#{@active_board_field_id_rv}": "#{@board_value_id}" or {$exists: false}}).count()

        if @limit > 0 and tasks_count >= @limit
          $kanban_board = $(e.currentTarget).parents(".kanban-board")
          $kanban_board.addClass "kanban-shake"
          setTimeout ->
            $kanban_board.removeClass "kanban-shake"
          , 1500

          JustdoSnackbar.show
            text: "Board has a limit of " + @limit + " Tasks"
            duration: 4000

        $(e.target).val ""

    return

  "click .kanban-board-hide": (e, tpl) ->
    board_value_id = @board_value_id
    visible_boards = @current_board_state_rv.visible_boards

    visible_boards.forEach (board, i) ->
      if board.board_value_id == board_value_id
        visible_boards.splice(i, 1)

    APP.justdo_kanban.setTaskKanbanViewStateBoardStateValue(@kanban_task_id_rv, @active_board_field_id_rv, "visible_boards", visible_boards)
    return
