_.extend CustomJustdoTasksLocks.prototype,
  _setupCollectionsHooks: ->
    @projectsInstallUninstallProcedures()

    @setupTasksLocks()

    return

  projectsInstallUninstallProcedures: ->
    self = @

    self.projects_collection.after.update (user_id, doc, fieldNames, modifier, options) ->
      feature_id = CustomJustdoTasksLocks.project_custom_feature_id # shortcut

      if (custom_features = modifier.$set?["conf.custom_features"])?
        previous_custom_features = @previous?.conf?.custom_features
        new_custom_features = doc.conf?.custom_features

        plugin_was_installed_before = false
        if _.isArray previous_custom_features
          plugin_was_installed_before = feature_id in previous_custom_features

        plugin_is_installed_after = false
        if _.isArray new_custom_features
          plugin_is_installed_after = feature_id in new_custom_features

        if not plugin_was_installed_before and plugin_is_installed_after
          self.performInstallProcedures(doc, user_id)

        if plugin_was_installed_before and not plugin_is_installed_after
          self.performUninstallProcedures(doc, user_id)

      return

    return

  setupTasksLocks: ->
    # Comment regarding testing whether or not the plugin is installed:
    #
    # We want to avoid hits on the db to check whether or not the plugin is
    # installed on a project for all tasks update/remove, which is quite
    # expensive. Therefore, we assume that the plugin is installed, and only,
    # in the very rare occasions, that the task is locked for edits, and, the
    # restricted fields are involved, only then, we check whether or not the
    # plugin is installed on the project - to ensure we need to block.
    @tasks_collection.before.update (user_id, doc, field_names, modifier, options) =>
      if @isUserAllowedToPerformRestrictedOperationsOnTaskDoc(doc, user_id)
        # User is not locked to perform the operation, operation is permitted for sure
        # (regardless of whether or not plugin is installed on the project, see
        # comment above: Comment regarding testing whether or not the plugin is installed)
        return true

      locking_members_removed = false
      if "users" in field_names
        locking_members_removed = JustdoHelpers.applyMongoModifiers doc, modifier, (e, modified_doc) =>
          old_users = doc.users
          modified_users = modified_doc.users

          removed_users = _.difference old_users, modified_users

          if _.intersection(removed_users, doc[CustomJustdoTasksLocks.locking_users_task_field]).length > 0
            return true

          return false

      any_restricted_field_updated = false
      for restricted_field_id in CustomJustdoTasksLocks.restricted_fields
        if restricted_field_id in field_names
          any_restricted_field_updated = true

      if not locking_members_removed and not any_restricted_field_updated
        # No locking members removed and no restricted field updated, operation is
        # permitted for sure
        return true

      if not (project_doc = @getProjectDocIfPluginInstalled(doc.project_id))?
        # Operation isn't permitted - but the plugin is not installed on the project
        # so we still allow it to happen.
        return true

      # Prevent the operation
      return false

    @tasks_collection.before.pseudo_remove (user_id, doc) =>
      if @isUserAllowedToPerformRestrictedOperationsOnTaskDoc(doc, user_id)
        # User is not locked to perform the operation, operation is permitted for sure
        # (regardless of whether or not plugin is installed on the project, see
        # comment above: Comment regarding testing whether or not the plugin is installed)
        return true

      if not (project_doc = @getProjectDocIfPluginInstalled(doc.project_id))?
        # Operation isn't permitted - but the plugin is not installed on the project
        # so we still allow it to happen.
        return true

      return false

    @justdo_projects.register "BeforeBulkUpdateExecution", (project_id, items_ids, modifier, user_id) =>
      # Find whether any user got removed in this bulk update, only if a user is removed, we care about
      # ensuring whether locks are respected.
      removed_users = []
      if (pulled_users = modifier.$pull?.users?.$in)?
        removed_users = removed_users.concat(pulled_users)

      if _.isEmpty removed_users
        # No user is removed, no chance we need to intervene.
        #
        # return true means we are not intervening at all with the bulk update. 
        return true

      if not (project_doc = @getProjectDocIfPluginInstalled(project_id))?
        # Plugin isn't installed on the project, we don't need to intervene
        return true

      # By here we know that we are removing users in this operation, and that
      # the plugin is installed for the project.

      # Start by executing all the bulk update ops that doesn't involve $pull
      pull_op = modifier.$pull
      delete modifier.$pull
      if not _.isEmpty(modifier)
        @justdo_projects._bulkUpdate(project_id, items_ids, modifier, user_id)

      removed_users_that_lock_nothing = []
      for removed_user_id in removed_users
        locked_tasks_query =
          _id:
            $in: items_ids
          "#{CustomJustdoTasksLocks.locking_users_task_field}": removed_user_id

        locked_tasks_ids = _.map @tasks_collection.find(locked_tasks_query, {fields: {_id: 1}}).fetch(), (x) -> x._id

        if locked_tasks_ids.length == 0
          # The removed_user_id isn't locking any task, can perform his removal in bulk with
          # others that aren't removing.
          removed_users_that_lock_nothing.push removed_user_id

          continue

        allowed_to_remove_from_tasks_ids = _.difference items_ids, locked_tasks_ids

        modifier =
          $pull:
            users:
              $in: [removed_user_id]
        @justdo_projects._bulkUpdate(project_id, allowed_to_remove_from_tasks_ids, modifier, user_id)

      # Take care of removed users that lock no tasks in items_ids
      modifier =
        $pull:
          users:
            $in: removed_users_that_lock_nothing
      @justdo_projects._bulkUpdate(project_id, items_ids, modifier, user_id)

      # We took control of the original bulkUpdate request, don't let the original bulkUpdate
      # request to continue! return false.
      return false
