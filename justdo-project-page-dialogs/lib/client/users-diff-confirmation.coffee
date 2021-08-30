options =
  max_printed_task_title: 40

getProjectPageModule = -> APP.modules.project_page

ProjectPageDialogs.JustdoTaskMembersDiffDialog =
  usersDiffConfirmationCb: (item_id, target_id, diff, confirm, cancel, options) ->
    required_users_info = _.union(diff.absent, diff.alien)
    APP.projects.ensureUsersPublicBasicUsersInfoLoaded required_users_info, ->
      options = _.extend {action_name: "move"}, (options or {})

      data =
        item_id: item_id
        target_id: target_id
        absent: if _.isEmpty diff.absent then null else diff.absent
        alien: if _.isEmpty diff.alien then null else diff.alien
        action_name: options.action_name

      message_template =
        JustdoHelpers.renderTemplateInNewNode(Template.users_diff_confirmation, data)

      bootbox.dialog
        title: "Members Update"
        message: message_template.node
        className: "members-update-dialog bootbox-new-design"

        onEscape: ->
          cancel()

          return true

        buttons:
          cancel:
            label: "Cancel"

            className: "btn-light"

            callback: ->
              cancel()

              return true

          continue:
            label: "Save"

            callback: =>
              module = getProjectPageModule()
              project = module.curProj()

              grid_control = module.gridControl()
              grid_data = module.gridData()

              # Note we set {each_options: {expand_only: true}} since
              # grid_control.getPathObjNonReactive works on visible items only
              item_path = grid_data.getCollectionItemIdPath(item_id, {each_options: {expand_only: true}})
              item_obj = grid_control.getPathObjNonReactive(item_path)

              members_ids_to_remove = []
              if perform_removals.get()
                members_ids_to_remove = _getProceedMembersIdsInReactiveVar members_to_remove

              members_ids_to_add = []
              if perform_additions.get()
                members_ids_to_add = _getProceedMembersIdsInReactiveVar members_to_add

              if _.isEmpty(members_ids_to_remove) and _.isEmpty(members_ids_to_add)
                # Nothing to do
                return confirm()

              items_to_edit = [item_id]
              items_to_assume_ownership_of = []
              items_to_cancel_ownership_transfer_of = []

              if item_obj.owner_id in members_ids_to_remove
                items_to_assume_ownership_of.push item_obj._id

              if item_obj.pending_owner_id in members_ids_to_remove
                items_to_cancel_ownership_transfer_of.push item_obj._id

              tree_traversing_options =
                expand_only: false
                filtered_tree: false

              grid_data.each item_path, tree_traversing_options, (section, item_type, item_obj, path, expand_state) ->
                items_to_edit.push item_obj._id

                if item_obj.owner_id in members_ids_to_remove
                  items_to_assume_ownership_of.push item_obj._id

                if item_obj.pending_owner_id in members_ids_to_remove
                  items_to_cancel_ownership_transfer_of.push item_obj._id

              bulk_updates = []
              if not _.isEmpty members_ids_to_remove
                bulk_updates.push (cb) ->
                  members_remove_modifier =
                    $pull:
                      users:
                        $in: members_ids_to_remove

                  project.bulkUpdate items_to_edit, members_remove_modifier, cb

              if not _.isEmpty members_ids_to_add
                bulk_updates.push (cb) ->
                  members_add_modifier =
                    $push:
                      users:
                        $each: members_ids_to_add

                  project.bulkUpdate items_to_edit, members_add_modifier, cb

              if not _.isEmpty items_to_assume_ownership_of
                bulk_updates.push (cb) ->
                  ownership_update_modifier =
                    $set:
                      owner_id: Meteor.userId()
                      pending_owner_id: null
                      is_removed_owner: null

                  project.bulkUpdate items_to_assume_ownership_of, ownership_update_modifier, cb

              if not _.isEmpty items_to_cancel_ownership_transfer_of
                bulk_updates.push (cb) ->
                  ownership_transfer_cancel_modifier =
                    $set:
                      pending_owner_id: null

                  project.bulkUpdate items_to_cancel_ownership_transfer_of, ownership_transfer_cancel_modifier, cb

              async.each bulk_updates,
                (bulk_update, cb) ->
                  bulk_update(cb)
                ,
                (err) ->
                  module = getProjectPageModule()

                  if err?
                    module.logger.error "Failed to update members"
                    console.log err

                    return confirm() # We confirm anyway, since we don't have a way to handle partial success and its consequences
                  else
                    return confirm()

              return
      return # ensureUsersPublicBasicUsersInfoLoaded

# Note: we assume only one confirmation dialog at a time
perform_additions = new ReactiveVar true
perform_removals = new ReactiveVar true
members_to_add = new ReactiveVar null
members_to_remove = new ReactiveVar null
notes = new ReactiveVar {}, JustdoHelpers.jsonComp

setMembersToAdd = (members_array) ->
  _setMembersInReactiveVar(members_to_add, members_array)

setMembersToRemove = (members_array) ->
  _setMembersInReactiveVar(members_to_remove, members_array)

_setMembersInReactiveVar = (reactive_var, members_array) ->
  if not members_array?
    return reactive_var.set null

  members = JustdoHelpers.getUsersDocsByIds(members_array)
  for member in members
    member.proceed = new ReactiveVar true
  reactive_var.set members

_getProceedMembersIdsInReactiveVar = (reactive_var) ->
  return _.map(_.filter(reactive_var.get(), (item) -> item.proceed.get()), (item) -> item._id)

_setProceedStateForAllMembersInReactiveVarFilterAware = (reactive_var, state) ->
  members = reactive_var.get()

  parent_tpl = Template.closestInstance "users_diff_confirmation"
  members_filter = parent_tpl.members_filter.get()

  members = JustdoHelpers.filterUsersDocsArray(members, members_filter, {sort: true})

  for member in members
    member.proceed.set state

  return

Template.users_diff_confirmation.onCreated ->
  # Init reactive vars
  module = getProjectPageModule()

  perform_additions.set true
  perform_removals.set true
  setMembersToAdd @data.alien
  setMembersToRemove @data.absent

  @members_filter = new ReactiveVar null

  @autorun =>
    grid_control = module.gridControl()
    grid_data = grid_control._grid_data
    grid_data.invalidateOnRebuild()

    members_ids_to_remove = _getProceedMembersIdsInReactiveVar members_to_remove

    if _.isEmpty members_ids_to_remove
      # Nothing to do
      notes.set {}

      return

    # Note we set {each_options: {expand_only: true}} since
    # grid_control.getPathObjNonReactive works on visible items only
    moved_item_path = grid_data.getCollectionItemIdPath(@data.item_id, {each_options: {expand_only: true}})
    moved_item_obj = grid_control.getPathObjNonReactive(moved_item_path)
    current_owner_id = moved_item_obj.owner_id

    _notes = {}

    if current_owner_id in members_ids_to_remove
      _notes.removing_current_task_owner = current_owner_id

    tree_traversing_options =
      expand_only: false
      filtered_tree: false

    _subtasks_owners_ids_pending_removal = {}
    grid_data.each moved_item_path, tree_traversing_options, (section, item_type, item_obj, path, expand_state) ->
      if (owner_id = item_obj.owner_id) in members_ids_to_remove
        _subtasks_owners_ids_pending_removal[owner_id] = true

    if not _.isEmpty _subtasks_owners_ids_pending_removal
      _notes.subtasks_owners_ids_pending_removal = _subtasks_owners_ids_pending_removal

    notes.set _notes

    return

Template.users_diff_confirmation.onDestroyed ->
  # Release memory... (garbage collector)
  setMembersToAdd null
  setMembersToRemove null

Template.users_diff_confirmation.helpers
  max_printed_task_title: -> options.max_printed_task_title
  task: -> APP.collections.Tasks.findOne @item_id
  target_task: -> APP.collections.Tasks.findOne @target_id
  sections: ->
    [
      {
        action_id: "add-aliens"
        section_label: "The following members <b>will be <u>ADDED</u></b>:"
        proceed_action_reactive_var: perform_additions
        action_members_reactive_var: members_to_add
        proceed_message: "Add"
        dont_proceed_message: "Don't add"
        proceed_status_fa_icon: "fa-check"
        dont_proceed_status_fa_icon: null
      },
      {
        action_id: "remove-absents"
        section_label: "The following members <b>will be <u>REMOVED</u></b>:"
        proceed_action_reactive_var: perform_removals
        action_members_reactive_var: members_to_remove
        proceed_message: "Remove"
        dont_proceed_message: "Keep"
        proceed_status_fa_icon: "fa-times"
        dont_proceed_status_fa_icon: null
      }
    ]

  display_notes_section: -> not _.isEmpty notes.get()
  notes: ->
    _notes = notes.get()
    notes_messages = []
    displayName = JustdoHelpers.displayName # shortcut

    if (removing_current_task_owner = _notes?.removing_current_task_owner)?
      moved_task_obj = APP.collections.Tasks.findOne @item_id
      notes_messages.push "#{displayName(removing_current_task_owner)} is task ##{moved_task_obj.seqId} owner. Following the membership cancellation, you will become the task owner."

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

Template.users_diff_confirmation.events
  "keyup .members-search-input": (e, template) ->
    value = $(e.target).val().trim()

    if _.isEmpty value
      return template.members_filter.set(null)
    else
      template.members_filter.set(value)

    return

Template.users_diff_action_section.helpers
  perform_action: -> @proceed_action_reactive_var.get()
  action_members: -> @action_members_reactive_var.get()
  action_members_filtered: ->
    action_members = @action_members_reactive_var.get()

    parent_tpl = Template.closestInstance "users_diff_confirmation"
    members_filter = parent_tpl.members_filter.get()

    return JustdoHelpers.filterUsersDocsArray(action_members, members_filter, {sort: true})
  section_width_trigger: ->
    if not members_to_add.get()? or not members_to_remove.get()?
      return true

Template.users_diff_action_section.events
  "click .select-all": ->
    _setProceedStateForAllMembersInReactiveVarFilterAware @action_members_reactive_var, true
    @proceed_action_reactive_var.set true

  "click .select-none": ->
    _setProceedStateForAllMembersInReactiveVarFilterAware @action_members_reactive_var, false
    @proceed_action_reactive_var.set false

Template.users_diff_user_btn.helpers
  proceed_user_message: -> Template.parentData(1).proceed_user_message
  dont_proceed_user_message: -> Template.parentData(1).dont_proceed_user_message

  status_fa_icon: ->
    if @proceed.get()
      return Template.parentData(1).proceed_status_fa_icon

    return Template.parentData(1).dont_proceed_status_fa_icon

  btn_title: ->
    user_doc = Template.instance().data

    display_name = JustdoHelpers.displayName(user_doc)
    if @proceed.get()
      message = Template.parentData(1).dont_proceed_message
    else
      message = Template.parentData(1).proceed_message

    return "Click to #{message} #{display_name}"

Template.users_diff_user_btn.events
  "click .user-btn": (e) ->
    current_state = @proceed.get()
    new_state = not current_state

    proceed_action_reactive_var = Template.parentData(1).proceed_action_reactive_var
    members = Template.parentData(1).action_members_reactive_var.get()

    if new_state and not proceed_action_reactive_var.get()
      # If the user want to proceed for this user make sure the action
      # is set as proceed.
      proceed_action_reactive_var.set true

    @proceed.set(new_state)

    if new_state == false
      # If all members are not proceed, mark action proceed as false
      for member in members
        if member.proceed.get()
          return

      proceed_action_reactive_var.set false
