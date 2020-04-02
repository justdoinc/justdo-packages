# FUNCTIONS
makeTasksDraggable = ->
  $(".kanban-task").draggable
    helper: "clone"
    start: (event, ui) ->
      $(ui.helper).width($(event.target).width())
  return


# ON CREATED
Template.project_pane_kanban.onCreated ->
  instance = @
  instance.kanban = new ReactiveVar null
  instance.kanbanActiveTask = new ReactiveVar null
  instance.kanbanMembersFilter = new ReactiveVar null
  instance.kanbanActiveBoardId = new ReactiveVar null

  # starting with the selected task
  if (selected_task_id = JD.activeItem())?
    @.kanbanActiveTask.set selected_task_id
  else
    @autorun =>
      if (instance.kanbanActiveTask.get())?
        return
      if not (task_obj  = JD.activeItem())?
        return
      instance.kanbanActiveTask.set task_obj
      return

  Tracker.autorun =>
    activeTask = instance.kanbanActiveTask.get()
    if activeTask?
      APP.justdo_kanban.createKanban activeTask._id
      APP.justdo_kanban.subscribeToKanbans activeTask._id

      kanban = APP.justdo_kanban.kanbans_collection.findOne(activeTask._id)
      if kanban?
        instance.kanban.set kanban[Meteor.userId()]

      setTimeout ->
        # Make Kanban Sortable
        $(".kanban-boards").sortable
          items: ".kanban-board"
          helper: "clone"
          tolerance: "pointer"
          cancel: ".kanban-board-control, .kanban-task-control, .kanban-task-add"
          update: ( event, ui ) ->
            active_task_id = instance.kanbanActiveTask.get()._id
            visible_boards = []
            $(".kanban-board").each ->
              visible_boards.push Blaze.getData($(this)[0])

            APP.justdo_kanban.updateKanban(active_task_id, "visible_boards", [])
            APP.justdo_kanban.updateKanban(active_task_id, "visible_boards", visible_boards)
            return

        makeTasksDraggable()

        $(".kanban-board-content").droppable
          drop: (event, ui) ->
            boards_field_id = instance.kanban.get().boards_field_id
            board_value_id = Blaze.getData(event.target).board_value_id
            task_id = Blaze.getData(ui.draggable[0])._id
            JD.collections.Tasks.update({_id: task_id}, {$set: {"#{boards_field_id}": board_value_id}})

            setTimeout ->
              makeTasksDraggable()
            , 500
            return

      , 1000


# HELPERS
Template.project_pane_kanban.helpers
  isSelectedTaskCollectionItem: -> APP.modules.project_page.getActiveGridItemType() == "default"

  selectedTask: ->
    return JD.activeItem()

  activeTask: ->
    activeTask = Template.instance().kanbanActiveTask.get()
    if activeTask?
      active_task_id = activeTask._id
      return APP.collections.Tasks.findOne(active_task_id)

  projects: ->
    project = APP.modules.project_page.project.get()
    if project?
      return APP.collections.Tasks.find({ "p:dp:is_project": true, project_id: project.id }, {sort: {"title": 1}}).fetch()

  boards: ->
    kanban = Template.instance().kanban.get()
    if kanban?
      return kanban.visible_boards

  boardLabel: (board_value_id) ->
    boards_field_id = Template.instance().kanban.get()?.boards_field_id
    gc = APP.modules.project_page.gridControl()
    label = gc?.getSchemaExtendedWithCustomFields()[boards_field_id]?.grid_values[board_value_id]?.txt
    return label

  boardIsHidden: (board_value_id) ->
    kanban = Template.instance().kanban.get()
    if kanban?
      visible_boards = kanban.visible_boards
      for board in visible_boards
        if board.board_value_id == board_value_id
          return "visible"

  allBoards: ->
    kanban = Template.instance().kanban.get()
    boards_field_id = kanban?.boards_field_id
    visible_boards = kanban?.visible_boards
    gc = APP.modules.project_page.gridControl()
    boards = gc?.getSchemaExtendedWithCustomFields()[boards_field_id]?.grid_values
    if boards?
      boards = Object.keys(boards)
      return boards

  tasks: (board_value_id) ->
    kanban = Template.instance().kanban.get()
    kanbanActiveTask = Template.instance().kanbanActiveTask.get()
    if kanbanActiveTask? and kanban?
      parentId = "parents." + kanbanActiveTask._id
      if kanban.query.users?
        tasks = APP.collections.Tasks.find({"#{parentId}": {$exists: true}, "#{kanban.boards_field_id}": "#{board_value_id}", "owner_id": kanban.query.users}, sort: kanban.sort)
      else
        tasks = APP.collections.Tasks.find({"#{parentId}": {$exists: true}, "#{kanban.boards_field_id}": "#{board_value_id}"}, sort: kanban.sort)
      return tasks

  activeMember: ->
    kanban = Template.instance().kanban.get()
    if kanban?
      if kanban.query.users != "all"
        return kanban.query.users

  thisIsActiveMember: (user_id) ->
    kanban = Template.instance().kanban.get()
    if kanban?
      if kanban.query.users == user_id
        return true

  boardCount: (board_value_id) ->
    kanban = Template.instance().kanban.get()
    kanbanActiveTask = Template.instance().kanbanActiveTask.get()
    if kanbanActiveTask? and kanban?
      parentId = "parents." + kanbanActiveTask._id
      count = APP.collections.Tasks.find({"#{parentId}": {$exists: true}, "#{kanban.boards_field_id}": "#{board_value_id}"}).count()
      if count > 0
        return count

  markCrossedLimit: (value_id) ->
    kanban = Template.instance().kanban.get()
    if not (visible_board = _.findWhere kanban.visible_boards, {board_value_id: value_id})?
      return ""
    if not visible_board.limit?
      return ""
    if not (kanbanActiveTask = Template.instance().kanbanActiveTask.get())?
      return ""

    active_task_id = kanbanActiveTask._id
    parentId = "parents." + active_task_id

    count = JD.collections.Tasks.find({"#{parentId}": {$exists: true}, "#{kanban.boards_field_id}": "#{value_id}"}).count()

    if count > visible_board.limit
      return "over-max-count"
    return ""

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
    kanban = Template.instance().kanban.get()
    boards_field_id = kanban?.boards_field_id
    gc = APP.modules.project_page.gridControl()
    label = gc?.getSchemaExtendedWithCustomFields()[boards_field_id]?.label
    return label

  members: ->
    kanbanMembersFilter = Template.instance().kanbanMembersFilter.get()
    kanbanActiveTask = Template.instance().kanbanActiveTask.get()
    if kanbanActiveTask?
      membersDocs = JustdoHelpers.filterUsersDocsArray(kanbanActiveTask.users, kanbanMembersFilter)
      return _.sortBy membersDocs, (member) -> JustdoHelpers.displayName(member)

  memberAvatar: (user_id) ->
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
  "click .kanban-board-task-add-button": (e, tmpl) ->
    $kanbanBoard = $(e.currentTarget).parents(".kanban-board")
    $KanbanBoardContent = $kanbanBoard.find(".kanban-board-content")
    $task_input = $kanbanBoard.find(".kanban-task-add-input")
    $task_input.focus()
    $KanbanBoardContent.animate { scrollTop: $task_input.offset().top }, 500
    return

  "click .js-kanban-selected-task": (e, tmpl) ->
    e.preventDefault()
    task = Blaze.getData(e.target)
    task_id = task._id
    tmpl.kanbanActiveTask.set task
    gcm = APP.modules.project_page.getCurrentGcm()
    gcm.setPath(["main", task_id], {collection_item_id_mode: true})
    return

  "click .js-kanban-field-item": (e, tmpl) ->
    e.preventDefault()
    visible_boards = []
    active_task_id = tmpl.kanbanActiveTask.get()._id
    field_id = Blaze.getData(e.target).field_id

    gc = APP.modules.project_page.gridControl()
    board_values = gc?.getSchemaExtendedWithCustomFields()[field_id]?.grid_values

    for value in Object.keys(board_values)
      if value != ""
        visible_boards.push {"board_value_id": value, "limit": 1000}

    APP.justdo_kanban.updateKanban(active_task_id, "boards_field_id", field_id)
    APP.justdo_kanban.updateKanban(active_task_id, "visible_boards", visible_boards)
    return

  "click .kanban-task": (e, tmpl) ->
    task_id = Blaze.getData(e.target)._id
    gcm = APP.modules.project_page.getCurrentGcm()
    gcm.setPath(["main", task_id], {collection_item_id_mode: true})
    return

  "keydown .kanban-task-add-input": (e, tmpl) ->
    if e.which == 13 or e.which == 9 # Enter or Tab
      kanbanActiveTask = tmpl.kanbanActiveTask.get()
      boards_field_id = tmpl.kanban.get().boards_field_id
      parent_task_id = kanbanActiveTask._id
      board_value_id = Blaze.getData(e.target).board_value_id
      board_limit = Blaze.getData(e.target).limit
      board_label = Blaze.getData(e.target).label

      APP.modules.project_page.gridControl()?._grid_data?.addChild "/" + parent_task_id + "/",
        project_id: JD.activeJustdo()._id
        title: $(e.target).val()
        "#{boards_field_id}": board_value_id

      parentId = "parents." + parent_task_id
      tasks = APP.collections.Tasks.find({"#{parentId}": {$exists: true}, "#{boards_field_id}": "#{board_value_id}"}).fetch()

      if board_limit > 0 and tasks.length > board_limit
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

    if e.which == 27 # Escape
       $(e.target).blur().val ""
    return

  "focusout .kanban-task-add-input": (e, tmpl) ->
    $(e.target).val ""
    return

  "click .kanban-task-remove": (e, tmpl) ->
    $task = $(e.currentTarget).parents(".kanban-task")
    parent_task_id = tmpl.kanbanActiveTask.get()._id
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

  "click .kanban-sort-item": (e, tmpl) ->
    e.preventDefault()
    active_task_id = tmpl.kanbanActiveTask.get()._id
    kanbanSortBy = $(e.currentTarget).attr "sortBy"
    kanbanSortByReverse = Object.values(tmpl.kanban.get().sort)[0]
    if kanbanSortByReverse == -1
      APP.justdo_kanban.updateKanban(active_task_id, "sort", {"#{kanbanSortBy}": 1})
    else
      APP.justdo_kanban.updateKanban(active_task_id, "sort", {"#{kanbanSortBy}": -1})
    return

  "click .kanban-board-hide": (e, tmpl) ->
    active_task_id = tmpl.kanbanActiveTask.get()._id
    board_value_id = Blaze.getData(e.target).board_value_id
    visible_boards = tmpl.kanban.get().visible_boards

    visible_boards.forEach (boards, i) ->
      if boards.board_value_id == board_value_id
        visible_boards.splice(i, 1)

    APP.justdo_kanban.updateKanban(active_task_id, "visible_boards", visible_boards)
    return

  "click .kanban-board-edit": (e, tmpl) ->
    tmpl.kanbanActiveBoardId.set Blaze.getData(e.target).board_value_id
    limit = Blaze.getData(e.target).limit
    if limit > 0
      $(".kanban-board-limit-input").val limit
    return

  "click .kanban-limit-save": (e, tmpl) ->
    $kanban_limit_input = $(".kanban-board-limit-input")
    active_task_id = tmpl.kanbanActiveTask.get()._id
    board_id = tmpl.kanbanActiveBoardId.get()
    limit_val = parseInt($kanban_limit_input.val())
    visible_boards = tmpl.kanban.get().visible_boards

    if limit_val > 0
      visible_boards.forEach (boards, i) ->
        if boards.board_value_id == board_id
          visible_boards[i].limit = limit_val

      APP.justdo_kanban.updateKanban(active_task_id, "visible_boards", visible_boards)
      $("#kanban-board-settings").modal "hide"
    else
      $kanban_limit_input.addClass "kanban-shake"
      setTimeout ->
        $kanban_limit_input.removeClass "kanban-shake"
      , 1500
    return

  "click .kanban-board-add-item": (e, tmpl) ->
    active_task_id = tmpl.kanbanActiveTask.get()._id
    board_id = Blaze.getData(e.target)
    kanban = tmpl.kanban.get()
    board_is_visible = $(e.target).hasClass "visible"
    if kanban?
      visible_boards = kanban.visible_boards
      if board_is_visible
        visible_boards.forEach (board, i) ->
          if board.board_value_id == board_id
            visible_boards.splice(i, 1)
      else
        visible_boards.push ({"board_value_id": board_id, "limit": 1000})

      APP.justdo_kanban.updateKanban(active_task_id, "visible_boards", visible_boards)
    return

  "keyup .kanban-member-selector-search": (e, tmpl) ->
    value = $(e.target).val().trim()
    if _.isEmpty value
      return tmpl.kanbanMembersFilter.set null
    else
      tmpl.kanbanMembersFilter.set value
    return

  "click .kanban-filter-member-item": (e, tmpl) ->
    e.preventDefault()
    user_id = Blaze.getData(e.target)
    active_task_id = tmpl.kanbanActiveTask.get()._id
    APP.justdo_kanban.updateKanban(active_task_id, "query", {"users": user_id})
    return

  "click .kanban-clear-member-filter": (e, tmpl) ->
    active_task_id = tmpl.kanbanActiveTask.get()._id
    APP.justdo_kanban.updateKanban(active_task_id, "query", {})
    return
