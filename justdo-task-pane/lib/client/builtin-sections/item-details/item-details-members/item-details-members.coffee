max_presented_avatars = 9

Template.task_pane_item_details_members.helpers
  box_grid:
    cols: max_presented_avatars

  primary_users: -> [@owner_id]

  secondary_users: ->
    res = JD.activeItemUsers().slice(0, max_presented_avatars)
    res = _.without res, @owner_id
    res = res.slice(0, max_presented_avatars - 1) # - 1 since we already use 1 space for the owner.

    return res

  controller:
    containersCustomContentGenerator: (user_doc) ->
      task_doc = JD.activeItem({owner_id: 1, is_removed_owner: 1})

      if task_doc?.owner_id == user_doc._id and task_doc?.is_removed_owner is true
        return """<div title="The task owner is no longer a member of the task" class="justdo-avatar-badge justdo-avatar-transfer-no-owner"><svg><use href="/layout/icons-feather-sprite.svg#jd-alert"></use></svg></div>"""

      return

  hiddenUsersCount: ->
    hidden_users_count = JD.activeItemUsers().length - max_presented_avatars

    if hidden_users_count > 0
      return hidden_users_count

    return null

Template.task_pane_item_details_members.events
  "click .hidden-users-count": (e, tpl) ->
    ProjectPageDialogs.members_management_dialog.open(tpl.data._id)

    return

Template.task_pane_item_details_members.helpers
