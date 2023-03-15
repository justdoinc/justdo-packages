_.extend JustdoDbMigrations.prototype,
  _registerCoreCollectionUpdatesTypes: ->
    self = @

    do => # To avoid job_type from mixing with the next one.
      membersProvided = (data) ->
        members_to_add_provided = data?.members_to_add? and not _.isEmpty(data.members_to_add)
        members_to_remove_provided = data?.members_to_remove? and not _.isEmpty(data.members_to_remove)

        items_to_assume_ownership_of_provided = data?.items_to_assume_ownership_of? and not _.isEmpty(data.items_to_assume_ownership_of)
        items_to_cancel_ownership_transfer_of_provided = data?.items_to_cancel_ownership_transfer_of? and not _.isEmpty(data.items_to_cancel_ownership_transfer_of)

        items_to_set_as_is_removed_owner_provided = data?.items_to_set_as_is_removed_owner? and not _.isEmpty(data.items_to_set_as_is_removed_owner)

        return {members_to_add_provided, members_to_remove_provided, items_to_assume_ownership_of_provided, items_to_cancel_ownership_transfer_of_provided, items_to_set_as_is_removed_owner_provided}

      job_type = "add-remove-members-to-tasks"
      @registerBatchedCollectionUpdatesType job_type,
        collection: APP.collections.Tasks
        use_raw_collection: true
        data_schema: new SimpleSchema
          project_id:
            type: String
          user_perspective_root_items: # The purpose of user_perspective_root_items is to be able to provide the user with
                                       # meaningful message about the tasks that are/were involved in the job.
                                       # Once a job is initiated, it is up to the job initiator to state which these
                                       # items are, we are not verifying, beyond ensuring that they are indeed in the
                                       # ids_to_update array.
            type: [String]
            optional: true
          members_to_add:
            type: [String]
            optional: true
          members_to_remove:
            type: [String]
            optional: true
          items_to_assume_ownership_of: # IMPORTANT:
                                        # 1. Allowed only if members_to_remove provided.
                                        # 2. We will ignore items that aren't in members_to_remove without a warning.
            type: [String]
            optional: true
          items_to_cancel_ownership_transfer_of: # IMPORANT: Same comment as the one left for items_to_assume_ownership_of
            type: [String]
            optional: true
          items_to_set_as_is_removed_owner: # IMPORANT: Same comment as the one left for items_to_assume_ownership_of
            type: [String]
            optional: true
          ensure_users_fully_removed_from_project_tasks_once_done:
            type: [String] # A list of users that we'll ensure that has no tasks belonging to them.
                           # it is necessary, since the remove operation can take long enough time for new
                           # tasks to be assigned to those users while we are processing it.
            optional: true
        jobsGatekeeper: (options) ->
          {data, ids_to_update, user_id} = options

          if user_id? # if user_id is null/undefined, we consider it a system-triggered job, for which
                      # we don't need to test whether the user is belonging to the project
            APP.projects.requireUserIsMemberOfProject data.project_id, user_id

            # CHECK PERMISSIONS:
            # Use the legacy BeforeBulkUpdateExecution handler to which the permissions plugin is binding
            # to set the hooks that ensures the process is allowed permissions wise.
            modifiers = @modifiersGenerator(data, user_id)
            for modifier in modifiers
              if not APP.projects.processHandlers("BeforeBulkUpdateExecution", data.project_id, ids_to_update, modifier, user_id)
                throw self._error "invalid-job-data", "For jobs of type #{job_type} the BeforeBulkUpdateExecution handler failed"

          {members_to_add_provided, members_to_remove_provided, items_to_assume_ownership_of_provided, items_to_cancel_ownership_transfer_of_provided, items_to_set_as_is_removed_owner_provided} = membersProvided(data)

          if not user_id? and items_to_assume_ownership_of_provided
            throw self._error "invalid-job-data", "For jobs of type #{job_type} triggered by the system (i.e. perform_as is null/undefined) the items_to_assume_ownership_of option can't be provided (there's is no performing user that can assume the ownership...)"

          if not members_to_add_provided and not members_to_remove_provided
            throw self._error "invalid-job-data", "For jobs of type #{job_type} at least one of the fields members_to_add/members_to_remove should be provided in the job's data object (and be non-empty)"

          if not members_to_remove_provided and (items_to_assume_ownership_of_provided or items_to_cancel_ownership_transfer_of_provided or items_to_set_as_is_removed_owner_provided)
            throw self._error "invalid-job-data", "For jobs of type #{job_type} items_to_assume_ownership_of and items_to_cancel_ownership_transfer_of are allowed only if members_to_remove is provided."

          user_perspective_root_items_provided = data?.user_perspective_root_items? and not _.isEmpty(data.user_perspective_root_items)

          if user_perspective_root_items_provided
            user_perspective_root_items = data.user_perspective_root_items

            for user_perspective_root_item in user_perspective_root_items
              if user_perspective_root_item not in ids_to_update
                throw self._error "invalid-job-data", "An item in #{user_perspective_root_item} is not part of the job's ids_to_update."

          return

        modifiersGenerator: (data, perform_as) ->
          modifiers = []

          {members_to_add_provided, members_to_remove_provided} = membersProvided(data)

          if members_to_add_provided
            modifiers.push
              $addToSet:
                users:
                  $each: data.members_to_add

          if members_to_remove_provided
            modifiers.push
              $pull:
                users:
                  $in: data.members_to_remove

          return modifiers

        afterModifiersExecutionOps: (items_ids, data, perform_as) ->
          {members_to_add_provided, members_to_remove_provided, items_to_assume_ownership_of_provided, items_to_cancel_ownership_transfer_of_provided, items_to_set_as_is_removed_owner_provided} = membersProvided(data)

          if members_to_add_provided
            APP.projects._grid_data_com._setPrivateDataDocsFreezeState(data.members_to_add, items_ids, false)
            # Important, if you change the logic here, note that in the process of inviteMember
            # we also call @_setPrivateDataDocsFreezeState()

            APP.projects._grid_data_com._removeIsRemovedOwnerForTasksBelongingTo(items_ids, data.members_to_add)

          if items_to_assume_ownership_of_provided
            items_to_assume_ownership_of_set = new Set(data.items_to_assume_ownership_of)
            items_to_assume_ownership_of_actual = _.filter(items_ids, (item_id) -> items_to_assume_ownership_of_set.has(item_id))

            if items_to_assume_ownership_of_actual.length > 0
              items_to_assume_ownership_of_modifier =
                $set:
                  owner_id: perform_as
                  pending_owner_id: null
                  is_removed_owner: null

              APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(items_to_assume_ownership_of_modifier)
              {err, result} = JustdoHelpers.pseudoBlockingRawCollectionUpdateInsideFiber(APP.collections.Tasks, {_id: {$in: items_to_assume_ownership_of_actual}}, items_to_assume_ownership_of_modifier, {multi: true})

              if err?
                throw new Error err

          if members_to_remove_provided
            APP.projects._grid_data_com._setPrivateDataDocsFreezeState(data.members_to_remove, items_ids, true)
            # Important, if you change the logic here, note that in the process of removeMember
            # we do something similar using a slight different API: _freezeAllProjectPrivateDataDocsForUsersIds

            # Remove pending owner that're removed users
            items_to_cancel_ownership_transfer_of_query =
              _id:
                $in: items_ids
              project_id: data.project_id
              pending_owner_id:
                $in: data.members_to_remove
            items_to_cancel_ownership_transfer_of_modifier =
              $set:
                pending_owner_id: null
            APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(items_to_cancel_ownership_transfer_of_modifier)
            {err, result} = JustdoHelpers.pseudoBlockingRawCollectionUpdateInsideFiber(APP.collections.Tasks, items_to_cancel_ownership_transfer_of_query, items_to_cancel_ownership_transfer_of_modifier, {multi: true})
            if err?
              throw new Error err

            # Set is_removed_owner=true for tasks owned by removed users
            items_to_set_as_is_removed_owner_query =
              _id:
                $in: items_ids
              project_id: data.project_id
              owner_id:
                $in: data.members_to_remove
            items_to_set_as_is_removed_owner_modifier =
              $set:
                is_removed_owner: true
            APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(items_to_set_as_is_removed_owner_modifier)
            {err, result} = JustdoHelpers.pseudoBlockingRawCollectionUpdateInsideFiber(APP.collections.Tasks, items_to_set_as_is_removed_owner_query, items_to_set_as_is_removed_owner_modifier, {multi: true})

            if err?
              throw new Error err

          return

        beforeJobMarkedAsDone: (data, perform_as) ->
          # The following introduced only for the case of removing a user from a certain JustDo.
          #
          # Since removing users from tasks can take long, we introduced the following mechanism
          # to keep ensuring that the users are actually removed from all the tasks.
          #
          # This is needed, since while we were removing the users from the tasks we found at the time of
          # the job creation other tasks might have been passed to the user as a result of:
          # 1. Other running jobs that are adding the user to tasks.
          # 2. Creation of new tasks that inherited the users list of their parents that might
          #    have included the user.
          # _ensureMemberRemovedFromAllTasksOfProject will create a new job if more tasks belonging
          # to the user will be found. If no tasks will be found - will end the process and do nothing.
          if _.isArray(data.ensure_users_fully_removed_from_project_tasks_once_done)
            for user_id in data.ensure_users_fully_removed_from_project_tasks_once_done
              if _.isString(user_id)
                APP.projects._ensureMemberRemovedFromAllTasksOfProject(data.project_id, user_id)

          return

      return # end of do =>

    return
