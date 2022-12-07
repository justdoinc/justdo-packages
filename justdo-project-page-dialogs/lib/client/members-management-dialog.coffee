ProjectPageDialogs.members_management_dialog = {}

JustdoHelpers.setupHandlersRegistry(ProjectPageDialogs.members_management_dialog)

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  #
  # Editor dialog
  #

  # Note: we assume only one confirmation dialog at a time
  users_to_keep = new ReactiveVar null
  users_to_add = new ReactiveVar null
  cascade = new ReactiveVar true
  notes = new ReactiveVar {}, JustdoHelpers.jsonComp
  proceed_type_rv = new ReactiveVar null

  _getUsersDocsByIdsWithProceedFlag = (members_array, default_proceed_val=true) ->
    # Returns APP.helpers.getUsersDocsByIds(members_array) output with
    # a `proceed` property assigned to each user doc.
    # The `proceed` property will have a reactive variable initiated to
    # default_proceed_val value


    # Note, _getUsersDocsByIdsWithProceedFlag is called outside of a computation
    # se we don't need to worry about reactivity and its consequence on proceed
    # values upon invalidations
    members = APP.helpers.getUsersDocsByIds(members_array)

    for member in members
      member.proceed = new ReactiveVar default_proceed_val
      member.disabled_reasons = new Set()
      member.disabled_reasons_dep = new Tracker.Dependency()

    return members

  restrictRemoveSelfAndOthers = ->
    proceed_type = null
    keep_users = users_to_keep.get()
    add_users = users_to_add.get()

    for user in keep_users
      if user.proceed.get() == false
        if user._id == Meteor.userId()
          proceed_type = "remove_self"
        else
          proceed_type = "remove_others"
        break
    
    for user in add_users
      if user.proceed.get() == true
        if user._id == Meteor.userId()
          proceed_type = "remove_self"
        else
          proceed_type = "remove_others"
        break

    if proceed_type == "remove_self"
      for user in keep_users
        if user._id != Meteor.userId()
          addDisabledReason(user, "You can't remove yourself and other users at the same time.")
      for user in add_users
        if user._id != Meteor.userId()
          addDisabledReason(user, "You can't remove yourself and other users at the same time.")
    else if proceed_type == "remove_others"
      for user in keep_users
        if user._id == Meteor.userId()
          addDisabledReason(user, "You can't remove yourself and other users at the same time.")
      for user in add_users
        if user._id == Meteor.userId()
          addDisabledReason(user, "You can't remove yourself and other users at the same time.")
    else
      for user in keep_users
        deleteDisabledReason(user, "You can't remove yourself and other users at the same time.")
      for user in add_users
        deleteDisabledReason(user, "You can't remove yourself and other users at the same time.")
    
    proceed_type_rv.set(proceed_type)
    return

  _setProceedStateForAllUsersInReactiveVarExcludingFiltered = (reactive_var, state) ->
    if proceed_type_rv.get() == "remove_self"
      return

    members = reactive_var.get()

    editor_tpl = Template.closestInstance "task_pane_item_details_members_editor"
    members_filter = editor_tpl.members_filter.get()

    members = JustdoHelpers.filterUsersDocsArray(members, members_filter, {sort: true})

    self_user = _.find members, (user) -> user._id == Meteor.userId()
    if self_user?
      members = _.without members, self_user
      
    for member in members
      member.proceed.set state

    restrictRemoveSelfAndOthers()

    return

  _getMembersIdsInReactiveVarByProceedState = (reactive_var, proceed_state=true) ->
    return _.map(_.filter(reactive_var.get(), (item) -> item.proceed.get() == proceed_state), (item) -> item._id)

  _isOwnerOfAnySubTask = (task_id) ->
    task_doc = APP.collections.Tasks.findOne task_id,
      fields:
        owner_id: 1
    
    user_id = Meteor.userId()

    if task_doc.owner_id == user_id
      return 1

    gd = APP.modules.project_page.gridData()
    task_path = gd?._grid_data_core.getAllCollectionPaths(task_id)?[0]

    result = false
    if task_path?
      gd.each(task_path, {}, (section, item_type, item_obj, path, expand_state) ->
        if item_obj.owner_id == user_id
          result = true
          return -2
        
        return
      )

    if result
      return 2

    return -1

  addDisabledReason = (user, reason) ->
    user.disabled_reasons.add(reason)
    user.disabled_reasons_dep.changed()
    return
  
  deleteDisabledReason = (user, reason) ->
    user.disabled_reasons.delete(reason)
    user.disabled_reasons_dep.changed()
    return

  addDisabledReasonIfNeccessary = (users, task_id) ->
    for user in users
      if user._id == Meteor.userId()
        is_owner_result = _isOwnerOfAnySubTask(task_id)
        if is_owner_result == 1
          addDisabledReason(user, "You are the owner of this task hence you cannot remove yourself from it")
        else if is_owner_result == 2
          addDisabledReason(user, "You own some tasks in the sub-tree hence you cannot remove yourself")
    
    return users

  setUsersLists = (task_id) ->
    augmented_task_doc = APP.collections.TasksAugmentedFields.findOne(task_id, {fields: {users: 1}})

    if not augmented_task_doc?
      return
    
    users = _.uniq(augmented_task_doc.users or [])

    if not (item_users = users)?
      throw module._error("unknown-data-context", "can't determine current task users")
    
    _users_to_keep = item_users

    if not (project_members = (project = module.curProj())?.getMembersIds({if_justdo_guest_include_ancestors_members_of_items: task_id}))?
      throw module._error("unknown-data-context", "can't determine project members")
    _users_to_add = _.difference project_members, item_users

    users_lists_already_exist = Tracker.nonreactive -> users_to_keep.get()?

    if not users_lists_already_exist
      users_to_keep.set addDisabledReasonIfNeccessary(JustdoHelpers.sortUsersDocsArrayByDisplayName(_getUsersDocsByIdsWithProceedFlag(_users_to_keep, true)), task_id)
      users_to_add.set JustdoHelpers.sortUsersDocsArrayByDisplayName(_getUsersDocsByIdsWithProceedFlag(_users_to_add, false))
    else
      current_users_to_keep_val = Tracker.nonreactive -> users_to_keep.get()
      current_users_to_keep_ids = _.map current_users_to_keep_val, (users) -> users._id

      new_current_users_to_keep_val_ids = _.difference _users_to_keep, current_users_to_keep_ids
      removed_current_users_to_keep_val_ids = _.difference current_users_to_keep_ids, _users_to_keep

      if new_current_users_to_keep_val_ids.length > 0 or removed_current_users_to_keep_val_ids.length > 0 
        new_users_to_keep_val = current_users_to_keep_val.slice() # shallow copy

        if removed_current_users_to_keep_val_ids.length > 0
          new_users_to_keep_val = _.filter new_users_to_keep_val, (user_with_proceed_flag)  ->
            if user_with_proceed_flag._id in removed_current_users_to_keep_val_ids
              return false

            return true

        if new_current_users_to_keep_val_ids.length > 0
          new_users_to_keep_val = new_users_to_keep_val.concat(_getUsersDocsByIdsWithProceedFlag(new_current_users_to_keep_val_ids, true))
          new_users_to_keep_val = JustdoHelpers.sortUsersDocsArrayByDisplayName(new_users_to_keep_val)
        
        users_to_keep.set(addDisabledReasonIfNeccessary(new_users_to_keep_val))

      current_users_to_add_val = Tracker.nonreactive -> users_to_add.get()
      current_users_to_add_val_ids = _.map current_users_to_add_val, (users) -> users._id

      new_current_users_to_add_val_ids = _.difference _users_to_add, current_users_to_add_val_ids
      removed_current_users_to_add_val_ids = _.difference current_users_to_add_val_ids, _users_to_add

      if new_current_users_to_add_val_ids.length > 0 or removed_current_users_to_add_val_ids.length > 0 
        new_users_to_add_val = current_users_to_add_val.slice() # shallow copy

        if removed_current_users_to_add_val_ids.length > 0
          new_users_to_add_val = _.filter new_users_to_add_val, (user_with_proceed_flag)  ->
            if user_with_proceed_flag._id in removed_current_users_to_add_val_ids
              return false

            return true

        if new_current_users_to_add_val_ids.length > 0
          new_users_to_add_val = new_users_to_add_val.concat(_getUsersDocsByIdsWithProceedFlag(new_current_users_to_add_val_ids, false))
          new_users_to_add_val = JustdoHelpers.sortUsersDocsArrayByDisplayName(new_users_to_add_val)

        users_to_add.set(new_users_to_add_val)

    return

  hasSubSubTasks = (task_id) ->
    if not (grid_data_core = APP.modules.project_page.gridData()?._grid_data_core)
      return false
    for i, subtask_id of grid_data_core.tree_structure[task_id]
      if grid_data_core.tree_structure[subtask_id]?
        return true
    
    return false
  
  getDescendantsCount = (task_path) ->
    if not (grid_data = APP.modules.project_page.gridData())?
      return 0

    i = 0
    grid_data.each task_path, {}, ->
      i += 1

    return i
  
  Template.task_pane_item_details_members_editor.onCreated ->
    data = @data

    # Note, for this dialog, we are not reactive for changes in the user rank in the
    # JustDo (admin/member/guest) while the dialog is on. The assumption is that the
    # dialog shouldn't be open for too long.
    #
    # For the same reason, we don't care about changes to the tree structure while
    # the dialog is open, namely, the ancesotrs/descendants of data._id . We check
    # it once when the dialog is opened - and that's it.

    # For guests, we want derive the users showing in the dialog from members of the
    # task's ancestors.
    @ancestors_users_subscription = null
    if module.curProj()?.isGuest() is true
      ancestors_ids_arr = _.keys APP.modules.project_page.mainGridControl()._grid_data._grid_data_core.getAllItemsKnownAncestorsIdsObj([data._id])
      @ancestors_users_subscription = APP.projects.subscribeTasksAugmentedFields(ancestors_ids_arr, ["users"])

    # The following is highly intensive operation on the server side for tasks
    # with big sub-tree.
    # If it'll turn out it is necessary (like in the case of guests?), need to consider strategy to
    # limit the amount of data we are asking -Daniel C.
    # descendants_ids_arr = _.keys APP.modules.project_page.mainGridControl()._grid_data._grid_data_core.getAllItemsKnownDescendantsIdsObj([data._id])
    # @descendants_users_subscription = APP.projects.subscribeTasksAugmentedFields(descendants_ids_arr, ["users"])

    @self_users_subscription = APP.projects.subscribeTasksAugmentedFields([data._id], ["users"])

    @autorun ->
      setUsersLists(data._id)

    @members_filter = new ReactiveVar null

    cascade.set true
    notes.set {}

    @autorun ->
      cascade_val = cascade.get()
      current_owner_id = APP.collections.Tasks.findOne(data._id, {fields: {owner_id: 1}})?.owner_id
      members_to_remove = _getMembersIdsInReactiveVarByProceedState(users_to_keep, false)

      grid_control = module.gridControl()
      grid_data = grid_control._grid_data
      grid_data.invalidateOnRebuild()

      #
      # Update notes reactive var
      #
      _notes = {}
      if current_owner_id in members_to_remove
        _notes.removing_current_task_owner = true

      if Meteor.userId() in members_to_remove
        _notes.removing_self = true

      if cascade_val
        tree_traversing_options =
          expand_only: false
          filtered_tree: false

        _subtasks_owners_ids_pending_removal = {}
        grid_data.each module.activeItemPath(), tree_traversing_options, (section, item_type, item_obj, path, expand_state) ->
          if (owner_id = item_obj.owner_id) in members_to_remove
            _subtasks_owners_ids_pending_removal[owner_id] = true

        if not _.isEmpty _subtasks_owners_ids_pending_removal
          _notes.subtasks_owners_ids_pending_removal = _subtasks_owners_ids_pending_removal

        # XXX Note that since "grid-item-changed" will emit only for grid-items and not
        # for all the items, the code below is not sufficient to react to any change to
        # owner_id.
        # Therefore, note regarding sub-tasks owners removal can be out-of-date.
        #
        # React to changes to items owner_id (which doesn't trigger rebuild)
        # current_computation = Tracker.currentComputation
        # _invalidateOnRelevantFieldsChange = (row, changed_fields) ->
        #   if "owner_id" in changed_fields
        #     current_computation.invalidate()

        #   return

        # grid_data.on "grid-item-changed", _invalidateOnRelevantFieldsChange
        # Tracker.onInvalidate =>
        #   grid_data.off "grid-item-changed", _invalidateOnRelevantFieldsChange

      notes.set _notes

    return

  Template.task_pane_item_details_members_editor.helpers
    users_to_keep: users_to_keep.get()
    users_to_add: users_to_add.get()
    sections: ->
      [
        {
          action_id: "add-users"
          caption: "Add Members · "
          action_users_reactive_var: users_to_add
          proceed_message: "Add"
          dont_proceed_message: "Don't add"
          proceed_status_fa_icon: "fa-check"
          dont_proceed_status_fa_icon: null
          no_members_msg: "No members to add"
        },
        {
          action_id: "keep-users"
          caption: "Task Members · "
          action_users_reactive_var: users_to_keep
          proceed_message: "Keep"
          dont_proceed_message: "Remove"
          proceed_status_fa_icon: null
          dont_proceed_status_fa_icon: "fa-times"
          no_members_msg: "This task is visible only to you, select members to share"
        }
      ]
    cascade: -> cascade.get()
    display_notes_section: -> not _.isEmpty notes.get()
    notes: ->
      _notes = notes.get()
      notes_messages = []
      displayName = JustdoHelpers.displayName # shortcut

      if (removing_current_task_owner = _notes?.removing_current_task_owner)?
        notes_messages.push "#{displayName(@owner_id)} is task ##{@seqId} owner. Following the membership cancellation, you will become the task owner."

      if _notes?.removing_self
        notes_messages.push "You're removing yourself from task ##{@seqId}. You won't be able to undo this action."
      if (subtasks_owners_ids_pending_removal = _notes?.subtasks_owners_ids_pending_removal)?
        subtasks_owners_ids_pending_removal = _.keys subtasks_owners_ids_pending_removal

        if subtasks_owners_ids_pending_removal.length == 1
          notes_messages.push "#{displayName(subtasks_owners_ids_pending_removal[0])} is an owner of some sub-tasks. Following the membership cancellation you will become the owner of these tasks."
        else
          message = ""

          for user_id, index in subtasks_owners_ids_pending_removal
            if index == subtasks_owners_ids_pending_removal.length - 1
              message += ", and #{displayName(user_id)}"
            else
              if index != 0
                message += ", "

              message += displayName(user_id)

          message += " are owners of some sub-tasks. Following their membership cancellation you will become the owner of all these sub-tasks."

          notes_messages.push message

      return notes_messages
    isRemovingSelf: -> proceed_type_rv.get() == "remove_self"

  Template.task_pane_item_details_members_editor.events
    "change .cascade-action-checkbox": (e) ->
      checked = e.target.checked

      if checked
        cascade.set true
      else
        cascade.set false

    "keyup .members-search-input": (e, template) ->
      value = $(e.target).val().trim()

      if _.isEmpty value
        return template.members_filter.set(null)
      else
        template.members_filter.set(value)

      return

  Template.task_pane_item_details_members_editor.onDestroyed ->
    users_to_keep.set null
    users_to_add.set null
    cascade.set true
    notes.set {}

    @ancestors_users_subscription?.stop()
    # @descendants_users_subscription?.stop()
    @self_users_subscription?.stop()

    return
  #
  # Editor dialog sections
  #

  Template.task_pane_item_details_members_editor_section.helpers
    perform_action: ->
      return @proceed_action_reactive_var.get()

    action_users_filtered: ->
      action_users = @action_users_reactive_var.get()

      editor_tpl = Template.closestInstance "task_pane_item_details_members_editor"
      members_filter = editor_tpl.members_filter.get()
      filtered_users = JustdoHelpers.filterUsersDocsArray(action_users, members_filter, {sort: true})
      self_user = _.find filtered_users, (user) -> user._id == Meteor.userId()
      if self_user?
        filtered_users = [self_user].concat(_.without(filtered_users, self_user))
      
      return filtered_users

    action_users_empty: ->
      return @action_users_reactive_var.get()?.length == 0

    showInviteMembersSection: ->
      if @action_id == "add-users" and (project = module.curProj()).isAdmin()
        return true

      return false


  Template.task_pane_item_details_members_editor_section.events
    "click .select-all": ->
      _setProceedStateForAllUsersInReactiveVarExcludingFiltered @action_users_reactive_var, true

    "click .select-none": ->
      _setProceedStateForAllUsersInReactiveVarExcludingFiltered @action_users_reactive_var, false

    "click .show-add-members-dialog": (e, tpl) ->
      ProjectPageDialogs.showMemberDialog()

  #
  # Editor dialog section user button
  #
  Template.task_pane_item_details_members_editor_user_btn.onCreated ->
    @user_doc = JustdoHelpers.getUsersDocsByIds @data._id

    return

  Template.task_pane_item_details_members_editor_user_btn.helpers
    user_doc: -> Template.instance().user_doc
    proceed_message: -> Template.parentData(1).proceed_message
    dont_proceed_message: -> Template.parentTemplate.parentData(1).dont_proceed_messageData(1).dont_proceed_message

    btn_title: ->
      user_doc = Template.instance().user_doc

      display_name = JustdoHelpers.displayName(user_doc)
      if @proceed.get()
        message = Template.parentData(1).dont_proceed_message
      else
        message = Template.parentData(1).proceed_message

      return "#{message} #{display_name}"

    showYouIfIsOwner: ->
      if Template.instance().user_doc._id == Meteor.userId()
        return "(You)"

      return ""
    
    disabledReason: ->
      @disabled_reasons_dep.depend()
      return @disabled_reasons.values().next().value


  Template.task_pane_item_details_members_editor_user_btn.events
    "click .user-btn": (e, tpl) ->
      if (disabled_reason = @disabled_reasons.values().next().value)
        JustdoSnackbar.show
          text: disabled_reason
        return
        
      clicked_user_id = @_id
      action_id = Template.parentData(1).action_id
      task_obj = Template.parentData(2)

      if not ProjectPageDialogs.members_management_dialog.processHandlers("BeforeUserItemClickProcessing", task_obj, action_id, clicked_user_id)
        return

      current_state = @proceed.get()
      new_state = not current_state

      @proceed.set(new_state)

      restrictRemoveSelfAndOthers()

      return

  ProjectPageDialogs.members_management_dialog.open = (task_id) ->
    if not (task_doc = APP.collections.Tasks.findOne(task_id, {fields: {seqId: 1, owner_id: 1}}))?
      APP.logger.error("openMembersManagementDialog: Couldn't find task: #{task_id}")

      return

    message_template =
      APP.helpers.renderTemplateInNewNode(Template.task_pane_item_details_members_editor, task_doc)

    bootbox.dialog
      title: "Edit Task Members"
      message: message_template.node
      animate: false
      className: "members-editor-dialog bootbox-new-design"

      onEscape: ->
        return true

      buttons:
        cancel:
          label: "Cancel"

          className: "btn-light"

          callback: ->
            return true

        submit:
          label: "Save"
          callback: =>
            project = module.curProj()

            if ($(".opened-by-members-managment-dialog").length > 0)
              # (It's a hack) Invite members dialog is open, can't save in that state
              return false

            members_to_remove = _getMembersIdsInReactiveVarByProceedState(users_to_keep, false)
            members_to_add = _getMembersIdsInReactiveVarByProceedState(users_to_add, true)

            if _.isEmpty(members_to_remove) and _.isEmpty(members_to_add)
              # Nothing to do
              return true

            execMembersEdit = ->
              grid_control = module.gridControl()
              grid_data = grid_control._grid_data

              active_item_obj = module.activeItemObjFromCollection({owner_id: 1, pending_owner_id: 1})

              items_to_edit = [task_doc._id]
              items_to_assume_ownership_of = []
              items_to_cancel_ownership_transfer_of = []

              if active_item_obj.owner_id in members_to_remove
                items_to_assume_ownership_of.push active_item_obj._id

              if active_item_obj.pending_owner_id in members_to_remove
                items_to_cancel_ownership_transfer_of.push active_item_obj._id

              if cascade.get()
                # If changes are applied to sub-tasks
                tree_traversing_options =
                  expand_only: false
                  filtered_tree: false

                grid_data.each module.activeItemPath(), tree_traversing_options, (section, item_type, item_obj, path, expand_state) ->
                  items_to_edit.push item_obj._id

                  if item_obj.owner_id in members_to_remove
                    items_to_assume_ownership_of.push item_obj._id

                  if item_obj.pending_owner_id in members_to_remove
                    items_to_cancel_ownership_transfer_of.push item_obj._id

              if not _.isEmpty members_to_remove
                members_remove_modifier =
                  $pull:
                    users:
                      $in: members_to_remove

                project.bulkUpdate items_to_edit, members_remove_modifier

              if not _.isEmpty members_to_add
                members_add_modifier =
                  $push:
                    users:
                      $each: members_to_add

                project.bulkUpdate items_to_edit, members_add_modifier

              if not _.isEmpty items_to_assume_ownership_of
                ownership_update_modifier =
                  $set:
                    owner_id: Meteor.userId()
                    pending_owner_id: null

                project.bulkUpdate items_to_assume_ownership_of, ownership_update_modifier

              if not _.isEmpty items_to_cancel_ownership_transfer_of
                ownership_transfer_cancel_modifier =
                  $set:
                    pending_owner_id: null

                project.bulkUpdate items_to_cancel_ownership_transfer_of, ownership_transfer_cancel_modifier

              return true
            
            task_id = JD.activeItemId()
            task_path = JD.activePath()
            if cascade.get() == true and hasSubSubTasks(task_id) and 
                (tasks_count = getDescendantsCount(task_path)+1) > ProjectPageDialogs.EDIT_MEMBER_CONFIRM_TASK_COUNT
              bootbox.confirm
                className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
                title: "Confirm edit members"
                message: JustdoHelpers.renderTemplateInNewNode(Template.confirm_edit_members_dialog, {
                  members_to_remove: if members_to_remove.length > 0 then members_to_remove else null
                  members_to_add: if members_to_add.length > 0 then members_to_add else null
                  tasks_count: tasks_count
                }).node
                callback: (result) ->
                  if result
                    execMembersEdit()
                    bootbox.hideAll()
                  return true
              return false
            else
              execMembersEdit()
            
            return true      

    $(".members-editor-dialog .members-search-input").focus()

    return