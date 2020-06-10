Template.project_pane_kanban_board_task.onRendered ->

  return


Template.project_pane_kanban_board_task.helpers
  memberAvatar: ->
    return JustdoAvatar.showUserAvatarOrFallback(Meteor.users.findOne(@owner_id))

  taskPriorityColor: ->
    return JustdoColorGradient.getColorRgbString @priority

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
          actionText: "Dismiss"
          onActionClick: =>
            JustdoSnackbar.close()
            return
      return
    return
