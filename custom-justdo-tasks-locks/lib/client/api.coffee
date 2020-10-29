_.extend CustomJustdoTasksLocks.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  setupCustomFeatureMaintainer: ->
    prereq_installer_comp = null
    task_update_collection_hook = null

    removeActivePathCustomPreReq = (prereq) =>
      prereq = JustdoHelpers.prepareOpreqArgs(prereq)

      # Make the prereq sensitive to features installation (this will actually cause invalidation for all)
      # TODO: we still don't support "refreshing" the prereq when the plugin is enabled - only when it is disabled
      APP.modules.project_page.curProj().isCustomFeatureEnabled(CustomJustdoTasksLocks.project_custom_feature_id)

      if not @isActiveUserAllowedToPerformRestrictedOperationsOnActiveTask()
        prereq[CustomJustdoTasksLocks.project_custom_feature_id] = "Can't perform operation on locked task"

      return prereq

    beforeEditHandler = (e, args) =>
      user_is_allowed_to_perform_restricted_ops =
        @isUserAllowedToPerformRestrictedOperationsOnTaskDoc(args.doc, Meteor.userId())

      restricted_fields = CustomJustdoTasksLocks.restricted_fields

      if not user_is_allowed_to_perform_restricted_ops and args.field in restricted_fields
        return false

      return true

    membersManagementDialogBeforeUserItemClickProcessing = (task_obj, action_id, clicked_user_id) =>
      locking_users = @getTaskDocLockingUsersIds(task_obj)

      if action_id == "keep-users" and clicked_user_id in locking_users
        JustdoSnackbar.show
          text: "Can't remove a locking user."
        return false

      return true

    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage CustomJustdoTasksLocks.project_custom_feature_id,
        installer: =>
          #
          # Setup prereq
          #
          prereq_installer_comp = Tracker.autorun =>
            if (gc = APP.modules.project_page.gridControl())?
              gc.registerCustomGridOperationPreReq("removeActivePath", removeActivePathCustomPreReq)

              gc.register "BeforeEditCell", beforeEditHandler

          ProjectPageDialogs.members_management_dialog.register "BeforeUserItemClickProcessing", membersManagementDialogBeforeUserItemClickProcessing

          # The following locks the task on ownership transfer
          task_update_collection_hook = @tasks_collection.after.update (user_id, doc, field_names, modifier, options) =>
            if doc.owner_id != Meteor.userId()
              # If the doc isn't owned by the current user, nothing to do
              return

            if not (new_pending_owner_id = modifier.$set?.pending_owner_id)?
              # If there is no pending owner, nothing to do
              return

            locking_users = @getTaskDocLockingUsersIds(doc)

            if Meteor.userId() in locking_users
              # Nothing to do, already locking
              return
  
            JustdoSnackbar.show
              text: "Lock Task?"
              actionText: "Yes"
              onActionClick: =>
                @toggleTaskLockedState doc._id, (err) =>
                  if err?
                    JustdoSnackbar.show
                      text: "Failed to lock task."
                  else
                    JustdoSnackbar.show
                      text: "Task locked"
                      actionText: "Dismiss"
                      onActionClick: =>
                        JustdoSnackbar.close()
                        return
                        
                      showSecondButton: true
                      secondButtonText: "Unlock"
                      onSecondButtonClick: =>
                        @toggleTaskLockedState doc._id
                        JustdoSnackbar.close()
                        return
                    return
                JustdoSnackbar.close()
                return
            return
          return

        destroyer: =>
          #
          # Remove prereq from all tabs
          #
          if not (all_tabs = APP.modules.project_page.getGridControlMux()?.getAllTabs())?
            all_tabs = {}

          for tab_id, tab_def of all_tabs
            tab_def.grid_control?.unregisterCustomGridOperationPreReq("removeActivePath", removeActivePathCustomPreReq)
            tab_def.grid_control?.unregister "BeforeEditCell", beforeEditHandler

          ProjectPageDialogs.members_management_dialog.unregister "BeforeUserItemClickProcessing", membersManagementDialogBeforeUserItemClickProcessing

          prereq_installer_comp?.stop()
          prereq_installer_comp = null

          task_update_collection_hook?.remove()
          task_update_collection_hook = null

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  getActiveTaskDocLockingUsersIds: ->
    if not (task_doc = APP.modules.project_page.activeItemObj())?
      return []

    return @getTaskDocLockingUsersIds(task_doc)

  isActiveUserLockingActiveTaskDoc: ->
    return Meteor.userId() in @getActiveTaskDocLockingUsersIds()

  isActiveUserAllowedToPerformRestrictedOperationsOnActiveTask: ->
    if not (task_doc = APP.modules.project_page.activeItemObj())?
      return false

    return @isUserAllowedToPerformRestrictedOperationsOnTaskDoc(task_doc, Meteor.userId())

  getActiveTaskDocLockingUsersDocs: ->
    return JustdoHelpers.getUsersDocsByIds(@getActiveTaskDocLockingUsersIds())

  toggleActiveTaskLockState: ->
    if not (task_doc = APP.modules.project_page.activeItemObj())?
      return

    @toggleTaskLockedState(task_doc._id)

    return 
