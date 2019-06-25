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

    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage CustomJustdoTasksLocks.project_custom_feature_id,
        installer: =>
          #
          # Setup prereq
          #
          prereq_installer_comp = Tracker.autorun =>
            if (gc = APP.modules.project_page.gridControl())?
              gc.registerCustomGridOperationPreReq("removeActivePath", removeActivePathCustomPreReq)

              gc.registerBeforeEditCellEvents(beforeEditHandler)

          return

        destroyer: =>
          #
          # Remove prereq from all tabs
          #
          if not (all_tabs = APP.modules.project_page.getGridControlMux()?.getAllTabs())?
            all_tabs = {}

          for tab_id, tab_def of all_tabs
            tab_def.grid_control?.unregisterCustomGridOperationPreReq("removeActivePath", removeActivePathCustomPreReq)
            tab_def.grid_control?.unregisterBeforeEditCellEvents(beforeEditHandler)

          prereq_installer_comp?.stop()
          prereq_installer_comp = null

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
