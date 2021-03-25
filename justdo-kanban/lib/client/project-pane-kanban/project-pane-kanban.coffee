# FUNCTIONS
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
  
  @autorun =>
    kanban_task_id = tpl.kanban_task_id_rv.get()
    if kanban_task_id?
      JD.subscribeItemsAugmentedFields [kanban_task_id], ["users"]
    
    return

  tpl.getKanbanTaskDoc = -> APP.collections.Tasks.findOne(tpl.kanban_task_id_rv.get())
  tpl.getCurrentBoardStateVisibleBoards = -> tpl.current_board_state_rv.get()?.visible_boards
  tpl.getCurrentBoardStateVisibleBoardsBoard = (board_id) ->
    visible_boards = tpl.getCurrentBoardStateVisibleBoards()

    return _.findWhere visible_boards, {board_value_id: board_id}
  tpl.setCurrentBoardStateValue = (key, value) -> APP.justdo_kanban.setTaskKanbanViewStateBoardStateValue(tpl.kanban_task_id_rv.get(), tpl.active_board_field_id_rv.get(), key, value)

  tpl.members_dropdown_search_input_state_rv = new ReactiveVar null
  tpl.projects_dropdown_search_input_state_rv = new ReactiveVar null

  tpl.kanban = new ReactiveVar null

  tpl.getCurrentGcFieldLabel = (field_id) ->
    if (gc = APP.modules.project_page.gridControl())?
      label = gc.getSchemaExtendedWithCustomFields()[field_id]?.label
      return label

    return ""

# ON RENDERED
Template.project_pane_kanban.onRendered ->
  tpl = @

  $(".kanban-member-selector").on "shown.bs.dropdown", ->
    $(".kanban-member-selector-search").focus()
    return

  $(".kanban-member-selector").on "hidden.bs.dropdown", ->
    tpl.members_dropdown_search_input_state_rv.set null
    $(".kanban-member-selector-search").val ""
    return

  return

# HELPERS
Template.project_pane_kanban.helpers
  tasksList: ->
    active_task = JD.activeItem({_id: 1, seqId: 1, title: 1})
    if active_task? and APP.modules.project_page.getActiveGridItemType() == "default"
      active_task = [active_task]
    else
      active_task = []

    project = APP.modules.project_page.project.get()
    if project?
      projects = APP.collections.Tasks.find({ "p:dp:is_project": true, project_id: project.id, $or: [{ "p:dp:is_archived_project": false }, { "p:dp:is_archived_project": {$exists: false} }] }, {sort: {"title": 1}}).fetch()
    else
      projects = []

    return [{
      title: "Selected task"
      tasks:  active_task
    }, {
      title: "Projects"
      tasks: projects
    }]

  kanbanTaskIdRv: -> Template.instance().kanban_task_id_rv.get()

  activeBoardFieldIdRv: -> Template.instance().active_board_field_id_rv.get()

  currentBoardStateRv: -> Template.instance().current_board_state_rv.get()

  activeTask: -> Template.instance().getKanbanTaskDoc()

  currentBoardStateVisibleBoards: -> Template.instance().getCurrentBoardStateVisibleBoards()

  boardIsVisible: ->
    for board in Template.instance().getCurrentBoardStateVisibleBoards()
      if board.board_value_id == @option_id
        return true

    return false

  allActiveBoardFieldOptions: ->
    active_board_field_id = Template.instance().active_board_field_id_rv.get()
    if (boards = APP.modules.project_page.gridControl()?.getSchemaExtendedWithCustomFields()?[active_board_field_id]?.grid_values)?
      return _.keys boards

    return []

  memberFilter: ->
    current_board_state = Template.instance().current_board_state_rv.get()

    if _.isString(owner_id_query_val = current_board_state.query?.owner_id)
      return owner_id_query_val

    return null

  thisIsActiveMember: (user_id) ->
    current_board_state = Template.instance().current_board_state_rv.get()

    if _.isString(owner_id_query_val = current_board_state.query?.owner_id)
      return owner_id_query_val == user_id

    return false

  fields: ->
    fields = [{"field_id": "state"}]

    if (custom_fields = JD.activeJustdo({custom_fields: 1})?.custom_fields)?
      for field in custom_fields
        if field.custom_field_type_id == "basic-select"
          fields.push {"field_id": field.field_id}

    return fields

  fieldIsActive: ->
    return @field_id == Template.instance().active_board_field_id_rv.get()

  fieldLabel: ->
    tpl = Template.instance()

    return tpl.getCurrentGcFieldLabel(@field_id)

  buttonFieldLabel: ->
    tpl = Template.instance()
    boards_field_id = Template.instance().active_board_field_id_rv.get()
    return tpl.getCurrentGcFieldLabel(boards_field_id)

  members: ->
    members_dropdown_search_input_state_rv =
      Template.instance().members_dropdown_search_input_state_rv.get()

    if (kanban_task_doc = APP.collections.TasksAugmentedFields.findOne(Template.instance().kanban_task_id_rv.get()))?
      kanban_user_docs = []

      for user_id in kanban_task_doc.users
        kanban_user_docs.push Meteor.users.findOne(user_id, { _id: 1 })

      return JustdoHelpers.filterUsersDocsArray(kanban_user_docs, members_dropdown_search_input_state_rv)

    return []

  memberAvatar: (user_id) ->
    return JustdoAvatar.showUserAvatarOrFallback(Meteor.users.findOne(user_id))

  memberName: (user_id) ->
    return JustdoHelpers.displayName(user_id)

  sortBy: ->
    current_board_state = Template.instance().current_board_state_rv.get()

    return Object.keys(current_board_state.sort)[0]

  sortByReverse: ->
    current_board_state = Template.instance().current_board_state_rv.get()
    if Object.values(current_board_state.sort)[0] > 0
      return true
    return false

  allActiveBoardFieldValues: ->
    active_board_field_id = Template.instance().active_board_field_id_rv.get()
    field_values = []

    if (schema = APP.modules?.project_page?.gridControl()?.getSchemaExtendedWithCustomFields())?
      for value_id, value_def of schema[active_board_field_id].grid_values
        field_values.push
          option_id: value_id
          label: value_def.html or value_def.txt

    return field_values

# EVENTS
Template.project_pane_kanban.events
  "click .js-kanban-selected-task": (e, tpl) ->
    e.preventDefault()
    tpl.kanban_task_id_rv.set @_id
    APP.modules.project_page.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(@_id)
    return

  "click .js-kanban-field-item": (e, tpl) ->
    e.preventDefault()
    APP.justdo_kanban.setTaskKanbanViewStateActiveFieldId(tpl.kanban_task_id_rv.get(), @field_id)
    return

  "click .kanban-sort-item": (e, tpl) ->
    e.preventDefault()
    task_id = tpl.kanban_task_id_rv.get()
    board_field_id = tpl.active_board_field_id_rv.get()
    sort_by = $(e.currentTarget).attr "sortBy"
    sort_by_reverse = Object.values(tpl.current_board_state_rv.get().sort)[0]
    APP.justdo_kanban.setTaskKanbanViewStateBoardStateValue(task_id, board_field_id, "sort", {"#{sort_by}": sort_by_reverse * -1})
    return

  "click .kanban-board-add-item": (e, tpl) ->
    task_id = tpl.kanban_task_id_rv.get()
    board_field_id = tpl.active_board_field_id_rv.get()
    board_id = Blaze.getData(e.target).option_id
    visible_boards = tpl.current_board_state_rv.get().visible_boards
    board_is_visible = $(e.target).hasClass "visible"

    if board_is_visible
      visible_boards.forEach (board, i) ->
        if board.board_value_id == board_id
          visible_boards.splice(i, 1)
    else
      visible_boards.push {"board_value_id": board_id, "limit": 100}

    APP.justdo_kanban.setTaskKanbanViewStateBoardStateValue(task_id, board_field_id, "visible_boards", visible_boards)
    return

  "keyup .kanban-member-selector-search": (e, tpl) ->
    value = $(e.target).val().trim()

    if _.isEmpty value
      tpl.members_dropdown_search_input_state_rv.set null

    tpl.members_dropdown_search_input_state_rv.set value

    return

  "keyup .kanban-projects-search": (e, tpl) ->
    value = $(e.target).val().trim()

    if _.isEmpty value
      tpl.projects_dropdown_search_input_state_rv.set null

    tpl.projects_dropdown_search_input_state_rv.set value

    return

  "click .kanban-filter-member-item": (e, tpl) ->
    e.preventDefault()

    user_id = Blaze.getData(e.target)._id

    tpl.setCurrentBoardStateValue("query", {owner_id: user_id})

    return

  "click .kanban-clear-member-filter": (e, tpl) ->
    e.preventDefault()

    tpl.setCurrentBoardStateValue("query", {})

    return

  "keydown .kanban-task-selector .dropdown-menu": (e, tpl) ->
    $dropdown_item = $(e.target).closest(".kanban-projects-search, .dropdown-item")

    if e.which == 38 # Up
      e.preventDefault()

      if ($prev_item = $dropdown_item.prevAll(".dropdown-item").first()).length > 0
        $prev_item.focus()
      else
        $(".kanban-projects-search", $dropdown_item.closest(".kanban-task-selector")).focus()

    if e.which == 40 # Down
      e.preventDefault()
      $dropdown_item.nextAll(".dropdown-item").first().focus()

    if e.which == 27 # Escape
      $(".kanban-task-selector button").dropdown "hide"

    return

  "keydown .kanban-member-selector .dropdown-menu": (e, tpl) ->
    $dropdown_item = $(e.target).closest(".kanban-member-selector-search, .dropdown-item")

    if e.which == 38 # Up
      e.preventDefault()

      if ($prev_item = $dropdown_item.prevAll(".dropdown-item").first()).length > 0
        $prev_item.focus()
      else
        $(".kanban-member-selector-search", $dropdown_item.closest(".kanban-member-selector")).focus()

    if e.which == 40 # Down
      e.preventDefault()
      $dropdown_item.nextAll(".dropdown-item").first().focus()

    if e.which == 27 # Escape
      $(".kanban-member-selector .kanban-member-selector-btn").dropdown "hide"

    return
