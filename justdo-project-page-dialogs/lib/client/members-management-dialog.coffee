ProjectPageDialogs.members_management_dialog = {}

JustdoHelpers.setupHandlersRegistry(ProjectPageDialogs.members_management_dialog)

getBatchedCollectionUpdatesQuery = ->
  return {type: "add-remove-members-to-tasks", "data.project_id": APP.modules.project_page.curProj().id}

APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

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
          addDisabledReason(user, "members_mgmt_dialog_cant_remove_self_and_other_users")
      for user in add_users
        if user._id != Meteor.userId()
          addDisabledReason(user, "members_mgmt_dialog_cant_remove_self_and_other_users")
    else if proceed_type == "remove_others"
      for user in keep_users
        if user._id == Meteor.userId()
          addDisabledReason(user, "members_mgmt_dialog_cant_remove_self_and_other_users")
      for user in add_users
        if user._id == Meteor.userId()
          addDisabledReason(user, "members_mgmt_dialog_cant_remove_self_and_other_users")
    else
      for user in keep_users
        deleteDisabledReason(user, "members_mgmt_dialog_cant_remove_self_and_other_users")
      for user in add_users
        deleteDisabledReason(user, "members_mgmt_dialog_cant_remove_self_and_other_users")

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

    if task_doc?.owner_id == user_id
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
    if users.length is 1
      addDisabledReason(users[0], "members_mgmt_dialog_cant_remove_self_only_member")
      return users

    for user in users
      if user._id == Meteor.userId()
        is_owner_result = _isOwnerOfAnySubTask(task_id)
        if is_owner_result == 1
          addDisabledReason(user, "members_mgmt_dialog_cant_remove_self_task_owner")
        else if is_owner_result == 2
          addDisabledReason(user, "members_mgmt_dialog_cant_remove_self_subtree_owner")

    return users

  setUsersLists = (task_id) ->
    augmented_task_doc = APP.collections.TasksAugmentedFields.findOne(task_id, {fields: {users: 1}})

    if not augmented_task_doc?
      return

    users = _.uniq(augmented_task_doc.users or [])

    if not (item_users = users)?
      throw project_page_module._error("unknown-data-context", TAPi18n.__("members_mgmt_dialog_cant_determine_task_users"))

    _users_to_keep = item_users

    if not (project_members = (project = project_page_module.curProj())?.getMembersIds({if_justdo_guest_include_ancestors_members_of_items: task_id}))?
      throw project_page_module._error("unknown-data-context", TAPi18n.__("members_mgmt_dialog_cant_determine_project_members"))
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
    if project_page_module.curProj()?.isGuest() is true
      ancestors_ids_arr = _.keys APP.modules.project_page.mainGridControl()._grid_data._grid_data_core.getAllItemsKnownAncestorsIdsObj([data._id])
      @ancestors_users_subscription = APP.projects.subscribeTasksAugmentedFields(ancestors_ids_arr, ["users"])

    # The following is highly intensive operation on the server side for tasks
    # with big sub-tree.
    # If it'll turn out it is necessary (like in the case of guests?), need to consider strategy to
    # limit the amount of data we are asking -Daniel C.
    # descendants_ids_arr = _.keys APP.modules.project_page.mainGridControl()._grid_data._grid_data_core.getAllItemsKnownDescendantsIdsObj([data._id])
    # @descendants_users_subscription = APP.projects.subscribeTasksAugmentedFields(descendants_ids_arr, ["users"])

    @self_users_subscription = APP.projects.subscribeTasksAugmentedFields([data._id], ["users"])

    @recent_batched_ops_subscription = Meteor.subscribe("getUsersRecentBatchedOps")

    @autorun ->
      setUsersLists(data._id)

    @members_filter = new ReactiveVar null

    cascade.set true
    notes.set {}

    @autorun ->
      cascade_val = cascade.get()
      current_owner_id = APP.collections.Tasks.findOne(data._id, {fields: {owner_id: 1}})?.owner_id
      members_to_remove = _getMembersIdsInReactiveVarByProceedState(users_to_keep, false)

      grid_control = project_page_module.gridControl()
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
        grid_data.each project_page_module.activeItemPath(), tree_traversing_options, (section, item_type, item_obj, path, expand_state) ->
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
          caption: TAPi18n.__ "member_management_dialog_add_members"
          action_users_reactive_var: users_to_add
          proceed_message: TAPi18n.__ "add"
          dont_proceed_message: TAPi18n.__ "members_mgmt_dialog_dont_add"
          proceed_status_fa_icon: "fa-check"
          dont_proceed_status_fa_icon: null
          no_members_msg: TAPi18n.__ "members_mgmt_dialog_no_members_to_add"
        },
        {
          action_id: "keep-users"
          caption: TAPi18n.__ "members_management_dialog_keep_members"
          action_users_reactive_var: users_to_keep
          proceed_message: TAPi18n.__ "keep"
          dont_proceed_message: TAPi18n.__ "remove"
          proceed_status_fa_icon: null
          dont_proceed_status_fa_icon: "fa-times"
          no_members_msg: TAPi18n.__ "members_mgmt_dialog_this_task_only_visible_to_you"
        }
      ]
    cascade: -> cascade.get()
    display_notes_section: -> not _.isEmpty notes.get()

    displayRecentBatchedOps: ->
      return APP.collections.DBMigrationBatchedCollectionUpdates.findOne(getBatchedCollectionUpdatesQuery())?

    recentBatchedOpsCount: ->
      recent_batched_ops = APP.collections.DBMigrationBatchedCollectionUpdates.find(getBatchedCollectionUpdatesQuery()).fetch()

      return recent_batched_ops.length

    notes: ->
      _notes = notes.get()
      notes_messages = []
      displayName = JustdoHelpers.displayName # shortcut

      if (removing_current_task_owner = _notes?.removing_current_task_owner)?
        notes_messages.push TAPi18n.__ "members_mgmt_dialog_removing_current_task_owner", {current_owner: displayName(@owner_id), seqId: @seqId}

      if _notes?.removing_self
        notes_messages.push TAPi18n.__ "members_mgmt_dialog_removing_self", {seqId: @seqId}

      if (subtasks_owners_ids_pending_removal = _notes?.subtasks_owners_ids_pending_removal)?
        subtasks_owners_ids_pending_removal = _.keys subtasks_owners_ids_pending_removal

        if (amount_of_subtask_owners_pending_removal = subtasks_owners_ids_pending_removal.length) == 1
          notes_messages.push TAPi18n.__ "members_mgmt_dialog_removing_subtree_owner", {subtree_owner: displayName(subtasks_owners_ids_pending_removal[0]), count: amount_of_subtask_owners_pending_removal}
        else
          subtask_owners = _.map subtasks_owners_ids_pending_removal, (user_id) -> displayName(user_id)
          last_subtask_owner = subtask_owners.pop()
          subtask_owners = subtask_owners.join " ,"
          notes_messages.push TAPi18n.__ "members_mgmt_dialog_removing_subtree_owner_plural", {subtree_owners: subtask_owners, last_subtree_owner: last_subtask_owner, count: amount_of_subtask_owners_pending_removal}

      return notes_messages

    isRemovingSelf: -> proceed_type_rv.get() == "remove_self"

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

    "click .note-close": (e, tpl) ->
      $el = $(e.target).parents("li").remove()

      if $(".notes li").length == 0
        notes.set {}

      return

  Template.task_pane_item_details_members_editor.onDestroyed ->
    users_to_keep.set null
    users_to_add.set null
    cascade.set true
    notes.set {}

    @ancestors_users_subscription?.stop()
    # @descendants_users_subscription?.stop()
    @self_users_subscription?.stop()

    @recent_batched_ops_subscription.stop()

    return
  #
  # Editor dialog sections
  #

  Template.task_pane_item_details_members_editor_section.onRendered ->
    $(".invite-new-member-dropdown").on "shown.bs.dropdown", ->
      $(".invite-members-section input").val("").focus()

      return

    return

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
      if @action_id == "add-users" and (project = project_page_module.curProj()).isAdmin()
        return true

      return false


  Template.task_pane_item_details_members_editor_section.events
    "click .select-all": ->
      _setProceedStateForAllUsersInReactiveVarExcludingFiltered @action_users_reactive_var, true

    "click .select-none": ->
      _setProceedStateForAllUsersInReactiveVarExcludingFiltered @action_users_reactive_var, false

    "click .invite-new-member": (e, tpl) ->
      ProjectPageDialogs.showMemberDialog()

      return

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
        return TAPi18n.__ "members_mgmt_dialog_you"

      return ""

    disabledReason: ->
      @disabled_reasons_dep.depend()
      if (disabled_reason = @disabled_reasons.values().next().value)?
        return disabled_reason
      
      return

  Template.task_pane_item_details_members_editor_user_btn.events
    "click .user-btn": (e, tpl) ->
      if (disabled_reason = @disabled_reasons.values().next().value)
        JustdoSnackbar.show
          text: TAPi18n.__ disabled_reason
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
      title: TAPi18n.__ "members_mgmt_dialog_title"
      message: message_template.node
      animate: false
      rtl_ready: true
      className: "members-editor-dialog bootbox-new-design"
      rtl_ready: true

      onEscape: ->
        return true

      buttons:
        cancel:
          label: TAPi18n.__ "cancel"

          className: "btn-light"

          callback: ->
            return true

        submit:
          label: TAPi18n.__ "save"
          callback: =>
            project = project_page_module.curProj()

            if ($(".opened-by-members-managment-dialog").length > 0)
              # (It's a hack) Invite members dialog is open, can't save in that state
              return false

            members_to_remove = _getMembersIdsInReactiveVarByProceedState(users_to_keep, false)
            members_to_add = _getMembersIdsInReactiveVarByProceedState(users_to_add, true)

            if _.isEmpty(members_to_remove) and _.isEmpty(members_to_add)
              # Nothing to do
              return true

            execMembersEdit = ->
              grid_control = project_page_module.gridControl()
              grid_data = grid_control._grid_data

              active_item_obj = project_page_module.activeItemObjFromCollection({owner_id: 1, pending_owner_id: 1})

              items_to_edit = [task_doc._id]
              items_to_assume_ownership_of = []

              if active_item_obj.owner_id in members_to_remove
                items_to_assume_ownership_of.push active_item_obj._id

              if cascade.get()
                # If changes are applied to sub-tasks
                tree_traversing_options =
                  expand_only: false
                  filtered_tree: false

                grid_data.each project_page_module.activeItemPath(), tree_traversing_options, (section, item_type, item_obj, path, expand_state) ->
                  items_to_edit.push item_obj._id

                  if item_obj.owner_id in members_to_remove
                    items_to_assume_ownership_of.push item_obj._id

              project.bulkUpdateTasksUsers
                tasks: items_to_edit
                user_perspective_root_items: [items_to_edit[0]]
                members_to_add: members_to_add
                members_to_remove: members_to_remove
                items_to_assume_ownership_of: items_to_assume_ownership_of

              return true

            task_id = JD.activeItemId()
            task_path = JD.activePath()
            task_count = 1 # The task itself
            if cascade.get()
              tasks_count = getDescendantsCount(task_path) + 1

            has_sub_sub_tasks_and_more_then_confirm_task_count = tasks_count > ProjectPageDialogs.EDIT_MEMBER_CONFIRM_TASK_COUNT
            crossed_immediate_execution_threshold = tasks_count > JustdoDbMigrations.batched_collection_updates_immediate_process_threshold_docs

            if has_sub_sub_tasks_and_more_then_confirm_task_count or crossed_immediate_execution_threshold
              bootbox.confirm
                rtl_ready: true
                className: "bootbox-new-design bootbox-new-design-simple-dialogs-default confirm-edit-members"
                title: TAPi18n.__ "members_mgmt_dialog_confirm_edit_members"
                buttons:
                  confirm:
                    label: TAPi18n.__ "confirm"
                message: JustdoHelpers.renderTemplateInNewNode(Template.confirm_edit_members_dialog, {
                  members_to_remove: if members_to_remove.length > 0 then members_to_remove else null
                  members_to_add: if members_to_add.length > 0 then members_to_add else null
                  tasks_count: tasks_count
                  has_sub_sub_tasks_and_more_then_confirm_task_count: has_sub_sub_tasks_and_more_then_confirm_task_count
                  crossed_immediate_execution_threshold: crossed_immediate_execution_threshold
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

  #
  # task_pane_item_details_members_editor_recent_batched_ops
  #
  Template.task_pane_item_details_members_editor_recent_batched_ops.helpers
    recentBatchedOps: -> APP.collections.DBMigrationBatchedCollectionUpdates.find(getBatchedCollectionUpdatesQuery(), {"sort": {"process_status_details.created_at": -1}})
    recentBatchedOpsCount: -> APP.collections.DBMigrationBatchedCollectionUpdates.find(getBatchedCollectionUpdatesQuery()).fetch().length
    isInProgress: -> @process_status is "in-progress"
    processedPercent: -> Math.floor((@process_status_details.processed / @process_status_details.total) * 100)
    detailedProcessed: -> 
      num_processed = @process_status_details.processed
      total_amount = @process_status_details.total
      return TAPi18n.__ "members_mgmt_dialog_detailed_progress", {num_processed, total_amount}

    opsMessage: ->
      op_object = @

      message_arr = []
      getMessage = -> message_arr.join(" ")

      total_tasks_in_job = op_object.process_status_details.total

      # user_perspective_root_items are the root items of the sub-trees involved
      # in the operation. This array might be empty. It is set during the time of
      # job creation by the job requester and it is completely arbitrary.
      #
      # The purpose of user_perspective_root_items is plainly to help the user
      # figure out what this job is about.
      user_perspective_root_items = op_object.data.user_perspective_root_items or []

      max_tasks_to_show_by_their_name = 3
      tasks_to_list_by_their_name = user_perspective_root_items.slice(0, max_tasks_to_show_by_their_name)
      tasks_werent_included_in_the_list_count = if user_perspective_root_items.length > max_tasks_to_show_by_their_name then user_perspective_root_items.length - max_tasks_to_show_by_their_name else 0

      members_to_add = @data.members_to_add or []
      members_to_remove = @data.members_to_remove or []

      if Meteor.userId() in members_to_remove
        # When the user himself is removed, he'll always be the only one involved in the operation
        message_arr.push TAPi18n.__("members_mgmt_dialog_removing_operating_user", {count: total_tasks_in_job})

        return getMessage()

      message_arr.push "<div class='recent-batched-msg-text'>"

      if members_to_add.length > 0 and members_to_remove.length > 0
        message_arr.push TAPi18n.__("members_mgmt_dialog_adding_and_removing_user", {add_count: members_to_add.length, remove_count: members_to_remove.length, tasks_count: total_tasks_in_job})
      else
        if members_to_add.length > 0
          message_arr.push TAPi18n.__("members_mgmt_dialog_adding_user", {count: members_to_add.length, tasks_count: total_tasks_in_job})
        if members_to_remove.length > 0
          message_arr.push TAPi18n.__("members_mgmt_dialog_removing_user", {count: members_to_remove.length, tasks_count: total_tasks_in_job})

      if tasks_to_list_by_their_name.length > 0
        message_arr.push TAPi18n.__("members_mgmt_dialog_under_task", {count: tasks_to_list_by_their_name.length, task_name: _.map(tasks_to_list_by_their_name, (task_id) -> "<span class='task'>#{JustdoHelpers.taskCommonName(APP.collections.Tasks.findOne(task_id), 50)}</span>").join(", ")})

        if tasks_werent_included_in_the_list_count > 0
          message_arr.push TAPi18n.__("members_mgmt_dialog_and_other_task", {count: tasks_werent_included_in_the_list_count})

      message_arr.push "</div>"

      if (process_status = op_object.process_status) == "pending"
        message_arr.push """<div title="#{TAPi18n.__ "members_mgmt_dialog_about_to_begin"}"><svg class="jd-icon about-to-begin"><use xlink:href="/layout/icons-feather-sprite.svg#clock"></use></svg></div>"""

      if process_status == "done"
        message_arr.push """<div title="#{TAPi18n.__ "done"}"><svg class="jd-icon done"><use xlink:href="/layout/icons-feather-sprite.svg#check"></use></svg></div>"""

      if process_status == "terminated"
        message_arr.push """<div title="#{TAPi18n.__ "members_mgmt_dialog_terminated"}"><svg class="jd-icon terminated"><use xlink:href="/layout/icons-feather-sprite.svg#alert-circle"></use></svg></div>"""

      if process_status == "error"
        message_arr.push """<div title="#{TAPi18n.__ "members_mgmt_dialog_error", {error_code: op_object.process_status_details?.error_data?.code}}"><svg class="jd-icon error"><use xlink:href="/layout/icons-feather-sprite.svg#slash"></use></svg></div>"""

      return getMessage()

  Template.task_pane_item_details_members_editor_recent_batched_ops.events
    "click .terminate": ->
      job_id = @_id

      bootbox.confirm
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        title: TAPi18n.__ "members_mgmt_dialog_terminate_title"
        message: TAPi18n.__ "members_mgmt_dialog_terminate_message"
        callback: (result) ->
          if result
            Meteor.call("terminateBatchedCollectionUpdatesJob", job_id)
          return true

      return

    "click .recent-batched-view-toggle": (e, tpl) ->
      $(".recent-batched-info").toggleClass "show-less"

      return
