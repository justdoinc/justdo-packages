max_presented_avatars = 9

Template.task_pane_item_details_members.onCreated ->
  @active_item_crv = JustdoHelpers.newComputedReactiveVar null, =>
    if not (active_item_id = @data?._id)?
      return null
    
    query_options = 
      fields:
        seqId: 1
        owner_id: 1
        is_removed_owner: 1
    
    return APP.collections.Tasks.findOne(active_item_id, query_options)

  @active_item_users_crv = JustdoHelpers.newComputedReactiveVar null, =>
    if not (active_item_id = @data?._id)?
      return []
    
    query_options = 
      fields:
        users: 1
    
    users = APP.collections.TasksAugmentedFields.findOne(active_item_id, query_options)?.users or []

    return _.uniq users
  
  return

Template.task_pane_item_details_members.helpers
  box_grid:
    cols: max_presented_avatars

  primary_users: ->
    tpl = Template.instance()
    active_item = tpl.active_item_crv.get()
    return [active_item?.owner_id]

  secondary_users: ->
    tpl = Template.instance()
    active_item = tpl.active_item_crv.get()
    uniq_users = tpl.active_item_users_crv.get()

    uniq_users = uniq_users.slice 0, max_presented_avatars
    users_without_owner = _.without uniq_users, active_item?.owner_id
    users_without_owner = users_without_owner.slice 0, (max_presented_avatars - 1) # - 1 since we already use 1 space for the owner.

    return users_without_owner

  controller: ->
    tpl = Template.instance()
    active_item = tpl.active_item_crv.get()
    ret = 
      containersCustomContentGenerator: (user_doc) ->
        if active_item?.owner_id == user_doc._id and active_item?.is_removed_owner is true
          return """<div title="The task owner is no longer a member of the task" class="justdo-avatar-badge justdo-avatar-transfer-no-owner"><svg><use href="/layout/icons-feather-sprite.svg#jd-alert"></use></svg></div>"""

        return
    
    return ret

  hiddenUsersCount: ->
    tpl = Template.instance()
    hidden_users_count = tpl.active_item_users_crv.get().length - max_presented_avatars

    if hidden_users_count > 0
      return hidden_users_count

    return null

Template.task_pane_item_details_members.events
  "click .hidden-users-count": (e, tpl) ->
    ProjectPageDialogs.members_management_dialog.open(tpl.data._id)

    return

Template.task_pane_item_details_members.helpers
