max_presented_avatars = 9

Template.task_pane_item_details_members.helpers
  box_grid:
    cols: max_presented_avatars

  primary_users: -> [@owner_id]

  secondary_users: -> _.without @users, @owner_id

  hiddenUsersCount: ->
    hidden_users_count = @users.length - max_presented_avatars

    if hidden_users_count > 0
      return hidden_users_count

    return null

Template.task_pane_item_details_members.events
  "click .hidden-users-count": (e, tpl) ->
    ProjectPageDialogs.members_management_dialog.open(tpl.data._id)

    return

Template.task_pane_item_details_members.helpers
