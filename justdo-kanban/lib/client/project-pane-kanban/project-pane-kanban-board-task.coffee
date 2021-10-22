# ON RENDERED
Template.project_pane_kanban_board_task.onRendered ->
  instance = @

  $(".kanban-task").draggable
    helper: "clone"
    start: (e, ui) ->
      $(ui.helper).width($(e.target).width())
      $(e.target).addClass "task-dragging"
      return
    stop: (e, ui) ->
      $(e.target).removeClass "task-dragging"
      return

  $(".kanban-board").droppable
    accept: ".kanban-task"
    drop: (e, ui) ->
      update_board = true

      data = Blaze.getData(e.target)
      task_id = Blaze.getData(ui.draggable[0])._id

      board_tasks = $(@).find(".kanban-task")

      # No need to update the board if the task dropped to the same board
      for task in board_tasks
        if Blaze.getData(task)._id == task_id
          update_board = false
          break

      if update_board
        JD.collections.Tasks.update({_id: task_id}, {$set: {"#{data.active_board_field_id_rv}": data.board_value_id}})

      return

  return

# HELPERS
Template.project_pane_kanban_board_task.helpers
  memberAvatar: ->
    return JustdoAvatar.showUserAvatarOrFallback(Meteor.users.findOne(@owner_id))

  taskPriorityColor: ->
    return JustdoColorGradient.getColorRgbString @priority

# EVENTS
Template.project_pane_kanban_board_task.events
  "click .kanban-task": (e, tpl) ->
    APP.modules.project_page.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(@_id)
    return

  "click .kanban-task-remove": (e, tpl) ->
    parent_task_id = Object.keys(@parents)[0]

    APP.modules.project_page.gridControl()?._grid_data?.removeParent "/#{parent_task_id}/#{@_id}/", (error) ->
      if error?
        JustdoSnackbar.show
          text: error.reason
          duration: 4000
      return
    return
