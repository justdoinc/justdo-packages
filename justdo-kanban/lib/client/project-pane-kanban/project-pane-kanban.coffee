# ON CREATED
Template.project_pane_kanban.onCreated ->
  instance = @
  instance.kanbanActiveTask = new ReactiveVar null
  instance.kanbanConfig = new ReactiveVar null
  instance.kanbanState = new ReactiveVar null
  instance.kanbanMembersFilter = new ReactiveVar null
  instance.kanbanActiveBoardId = new ReactiveVar null
  instance.kanbanStateId = new ReactiveVar "state"

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
      kanban_config = APP.justdo_kanban.kanbans_collection.findOne(activeTask._id)
      kanbanStateId = instance.kanbanStateId.get()
      if kanban_config?
        instance.kanbanConfig.set kanban_config[Meteor.userId()]
        instance.kanbanState.set kanban_config[Meteor.userId()].states[kanbanStateId]

      setTimeout ->
        # Make Kanban Sortable
        $(".kanban-boards").sortable
          items: ".kanban-board"
          helper: "clone"
          tolerance: "pointer"
          cancel: ".kanban-board-control, .kanban-task-control, .kanban-task-add"

        $(".kanban-board-content").sortable
          items: ".kanban-task"
          tolerance: "pointer"
          connectWith: ".kanban-board-content"
          cancel: ".kanban-task-control"
          receive: (event, ui) ->
            state_id = instance.kanbanState.get().field_id
            board_option_id = Blaze.getData(event.target).option_id
            task_id = Blaze.getData(ui.item[0])._id
            JD.collections.Tasks.update({_id: task_id}, {$set: {"#{state_id}": board_option_id}})
            return
      , 1000


# HELPERS
Template.project_pane_kanban.helpers
  selectedTask: ->
    return JD.activeItem()

  activeTask: ->
    return Template.instance().kanbanActiveTask.get()

  projects: ->
    project = APP.modules.project_page.project.get()
    if project?
      return APP.collections.Tasks.find({ "p:dp:is_project": true, project_id: project.id }, {sort: {"title": 1}}).fetch()

  tasks: (option_id) ->
    kanbanState = Template.instance().kanbanState.get()
    kanbanActiveTask = Template.instance().kanbanActiveTask.get()
    kanbanActiveMember = Template.instance().kanbanConfig.get().memberFilter
    kanbanSortBy = Template.instance().kanbanConfig.get().sortBy.option
    kanbanSortByReverse = Template.instance().kanbanConfig.get().sortBy.reverse
    if kanbanActiveTask? and kanbanState?
      kanbanStateId = kanbanState.field_id
      active_task_id = kanbanActiveTask._id
      parentId = "parents." + active_task_id
      if kanbanActiveMember?
        tasks = APP.collections.Tasks.find({"#{parentId}": {$exists: true}, "#{kanbanStateId}": "#{option_id}", "owner_id": kanbanActiveMember}).fetch()
      else
        tasks = APP.collections.Tasks.find({"#{parentId}": {$exists: true}, "#{kanbanStateId}": "#{option_id}"}).fetch()

      tasks = _.sortBy(tasks, kanbanSortBy)

      if kanbanSortByReverse
        tasks = tasks.reverse()

      return tasks

  activeMember: ->
    kanbanConfig = Template.instance().kanbanConfig.get()
    if kanbanConfig?
      return kanbanConfig.memberFilter

  thisIsActiveMember: (user_id) ->
    kanbanConfig = Template.instance().kanbanConfig.get()
    if kanbanConfig?
      if kanbanConfig.memberFilter == user_id
        return true

  boardCount: (option_id) ->
    kanbanState = Template.instance().kanbanState.get()
    kanbanActiveTask = Template.instance().kanbanActiveTask.get()
    if kanbanActiveTask? and kanbanState?
      kanbanStateId = kanbanState.field_id
      active_task_id = kanbanActiveTask._id
      parentId = "parents." + active_task_id
      count = APP.collections.Tasks.find({"#{parentId}": {$exists: true}, "#{kanbanStateId}": "#{option_id}"}).count()
      if count > 0
        return count

  markCrossedLimit: (option_id) ->
    kanbanState = Template.instance().kanbanState.get()
    if not (field_options = _.findWhere kanbanState.field_options.select_options, {option_id: option_id})?
      return ""
    if not field_options.limit?
      return ""
    if not (kanbanActiveTask = Template.instance().kanbanActiveTask.get())?
      return ""

    kanbanStateId = kanbanState.field_id
    active_task_id = kanbanActiveTask._id
    parentId = "parents." + active_task_id
    count = JD.collections.Tasks.find({"#{parentId}": {$exists: true}, "#{kanbanStateId}": "#{option_id}"}).count()
    if count > field_options.limit
      return "over-max-count"
    return ""

  taskPriorityColor: (priority) ->
    return JustdoColorGradient.getColorRgbString priority

  customFields: ->
    customFields = []
    if JD.activeJustdo()?
      if JD.activeJustdo().custom_fields?
        for field in JD.activeJustdo().custom_fields
          if field.custom_field_type_id == "basic-select"
            customFields.push field
        return customFields

  boards: ->
    kanbanBoards = Template.instance().kanbanState.get()
    if kanbanBoards?
      return kanbanBoards.field_options.select_options

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
    kanbanConfig = Template.instance().kanbanConfig.get()
    if kanbanConfig?
      return kanbanConfig.sortBy.option

  sortByReverse: ->
    kanbanConfig = Template.instance().kanbanConfig.get()
    if kanbanConfig?
      return kanbanConfig.sortBy.reverse


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

  "click .js-kanban-state-item": (e, tmpl) ->
    e.preventDefault()
    
    active_task_id = tmpl.kanbanActiveTask.get()._id
    state = Blaze.getData(e.target)
    APP.justdo_kanban.addState(active_task_id, state)
    tmpl.kanbanStateId.set state.field_id
    $(".kanban-state-selector button").text $(e.target).text()
    return

  "click .js-kanban-state-item-default": (e, tmpl) ->
    e.preventDefault()

    tmpl.kanbanStateId.set "state"
    $(".kanban-state-selector button").text $(e.target).text()
    return

  "click .kanban-task": (e, tmpl) ->
    task_id = Blaze.getData(e.target)._id
    gcm = APP.modules.project_page.getCurrentGcm()
    gcm.setPath(["main", task_id], {collection_item_id_mode: true})
    return

  "keydown .kanban-task-add-input": (e, tmpl) ->
    if e.which == 13 or e.which == 9 # Enter or Tab
      kanbanActiveTask = tmpl.kanbanActiveTask.get()
      kanbanState = tmpl.kanbanState.get()
      parent_task_id = kanbanActiveTask._id
      board_id = Blaze.getData(e.target).option_id
      board_limit = Blaze.getData(e.target).limit
      board_label = Blaze.getData(e.target).label

      options = {
        "state": kanbanState.field_id
        "board": board_id
        "title": $(e.target).val()
        "project_id": JD.activeJustdo()._id
      }

      APP.modules.project_page.gridControl()?._grid_data?.addChild "/" + parent_task_id + "/",
        project_id: options.project_id
        title: options.title

      APP.justdo_kanban.addSubTask parent_task_id, options

      kanbanStateId = kanbanState.field_id
      parentId = "parents." + parent_task_id
      tasks = APP.collections.Tasks.find({"#{parentId}": {$exists: true}, "#{kanbanStateId}": "#{board_id}"}).fetch()

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

  "click .kanban-sort-by-date": (e, tmpl) ->
    e.preventDefault()

    active_task_id = tmpl.kanbanActiveTask.get()._id
    kanbanSortBy = tmpl.kanbanConfig.get().sortBy.option
    if kanbanSortBy == "createdAt"
      kanbanSortByReverse = tmpl.kanbanConfig.get().sortBy.reverse
      if kanbanSortByReverse
        APP.justdo_kanban.setSortBy(active_task_id, "createdAt", false)
      else
        APP.justdo_kanban.setSortBy(active_task_id, "createdAt", true)
    else
      APP.justdo_kanban.setSortBy(active_task_id, "createdAt", false)
    return

  "click .kanban-sort-by-priority": (e, tmpl) ->
    e.preventDefault()

    active_task_id = tmpl.kanbanActiveTask.get()._id
    kanbanSortBy = tmpl.kanbanConfig.get().sortBy.option
    if kanbanSortBy == "priority"
      kanbanSortByReverse = tmpl.kanbanConfig.get().sortBy.reverse
      if kanbanSortByReverse
        APP.justdo_kanban.setSortBy(active_task_id, "priority", false)
      else
        APP.justdo_kanban.setSortBy(active_task_id, "priority", true)
    else
      APP.justdo_kanban.setSortBy(active_task_id, "priority", false)
    return

  "click .kanban-sort-by-due-date": (e, tmpl) ->
    e.preventDefault()

    active_task_id = tmpl.kanbanActiveTask.get()._id
    kanbanSortBy = tmpl.kanbanConfig.get().sortBy.option
    if kanbanSortBy == "due_date"
      kanbanSortByReverse = tmpl.kanbanConfig.get().sortBy.reverse
      if kanbanSortByReverse
        APP.justdo_kanban.setSortBy(active_task_id, "due_date", false)
      else
        APP.justdo_kanban.setSortBy(active_task_id, "due_date", true)
    else
      APP.justdo_kanban.setSortBy(active_task_id, "due_date", false)
    return

  "click .kanban-board-hide": (e, tmpl) ->
    active_task_id = tmpl.kanbanActiveTask.get()._id
    state_id = tmpl.kanbanState.get().field_id
    board_id = Blaze.getData(e.target).option_id
    APP.justdo_kanban.updateStateOption(active_task_id, state_id, board_id, "visible", false)
    return

  "click .kanban-board-edit": (e, tmpl) ->
    active_task_id = tmpl.kanbanActiveTask.get()._id
    state_id = tmpl.kanbanState.get().field_id
    tmpl.kanbanActiveBoardId.set Blaze.getData(e.target).option_id
    limit = Blaze.getData(e.target).limit
    if limit > 0
      $(".kanban-board-limit-input").val limit
    return

  "click .kanban-limit-save": (e, tmpl) ->
    $kanban_limit_input = $(".kanban-board-limit-input")
    active_task_id = tmpl.kanbanActiveTask.get()._id
    state_id = tmpl.kanbanState.get().field_id
    board_id = tmpl.kanbanActiveBoardId.get()
    limit_val = $kanban_limit_input.val()
    if limit_val > 0
      APP.justdo_kanban.updateStateOption(active_task_id, state_id, board_id, "limit", limit_val)
      $("#kanban-board-settings").modal "hide"
    else
      $kanban_limit_input.addClass "kanban-shake"
      setTimeout ->
        $kanban_limit_input.removeClass "kanban-shake"
      , 1500
    return

  "click .kanban-board-add-item": (e, tmpl) ->
    active_task_id = tmpl.kanbanActiveTask.get()._id
    state_id = tmpl.kanbanState.get().field_id
    option_id = Blaze.getData(e.target).option_id
    visibility = Blaze.getData(e.target).visible

    if visibility
      new_value = false
    else
      new_value = true

    APP.justdo_kanban.updateStateOption(active_task_id, state_id, option_id, "visible", new_value)
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
    APP.justdo_kanban.setMemberFilter(active_task_id, user_id)
    return

  "click .kanban-clear-member-filter": (e, tmpl) ->
    active_task_id = tmpl.kanbanActiveTask.get()._id
    APP.justdo_kanban.setMemberFilter(active_task_id, null)
    return
