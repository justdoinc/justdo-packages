_.extend JustdoDbMigrations.prototype,
  _registerCoreCollectionUpdatesTypes: ->
    self = @

    do => # To avoid job_type from mixing with the next one.
      membersProvided = (data) ->
        members_to_add_provided = data?.members_to_add? and not _.isEmpty(data.members_to_add)
        members_to_remove_provided = data?.members_to_remove? and not _.isEmpty(data.members_to_remove)

        items_to_assume_ownership_of_provided = data?.items_to_assume_ownership_of? and not _.isEmpty(data.items_to_assume_ownership_of)
        items_to_cancel_ownership_transfer_of_provided = data?.items_to_cancel_ownership_transfer_of? and not _.isEmpty(data.items_to_cancel_ownership_transfer_of)

        return {members_to_add_provided, members_to_remove_provided, items_to_assume_ownership_of_provided, items_to_cancel_ownership_transfer_of_provided}

      job_type = "add-remove-members-to-tasks"
      @registerBatchedCollectionUpdatesType job_type,
        collection: APP.collections.Tasks
        use_raw_collection: true
        data_schema: new SimpleSchema
          project_id:
            type: String
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

        jobsGatekeeper: (options) ->
          {data, ids_to_update, user_id} = options

          APP.projects.requireUserIsMemberOfProject data.project_id, user_id

          {members_to_add_provided, members_to_remove_provided, items_to_assume_ownership_of_provided, items_to_cancel_ownership_transfer_of_provided} = membersProvided(data)

          if not members_to_add_provided and not members_to_remove_provided
            throw self._error "invalid-job-data", "For jobs of type #{job_type} at least one of the fields members_to_add/members_to_remove should be provided in the job's data object (and be non-empty)"

          if not members_to_remove_provided and (items_to_assume_ownership_of_provided or items_to_cancel_ownership_transfer_of_provided)
            throw self._error "invalid-job-data", "For jobs of type #{job_type} items_to_assume_ownership_of and items_to_cancel_ownership_transfer_of are allowed only if members_to_remove is provided."

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
          {members_to_add_provided, members_to_remove_provided, items_to_assume_ownership_of_provided, items_to_cancel_ownership_transfer_of_provided} = membersProvided(data)

          if members_to_add_provided
            APP.projects._grid_data_com._setPrivateDataDocsFreezeState(data.members_to_add, items_ids, false)
            # Important, if you change the logic here, note that in the process of inviteMember
            # we also call @_setPrivateDataDocsFreezeState()

            APP.projects._grid_data_com._removeIsRemovedOwnerForTasksBelongingTo(items_ids, data.members_to_add)

          if members_to_remove_provided
            APP.projects._grid_data_com._setPrivateDataDocsFreezeState(data.members_to_remove, items_ids, true)
            # Important, if you change the logic here, note that in the process of removeMember
            # we do something similar using a slight different API: _freezeAllProjectPrivateDataDocsForUsersIds

          if items_to_assume_ownership_of_provided
            items_to_assume_ownership_of_set = new Set(data.items_to_assume_ownership_of)
            items_to_assume_ownership_of_actual = _.filter(items_ids, (item_id) -> items_to_assume_ownership_of_set.has(item_id))

            if items_to_assume_ownership_of_actual.length > 0
              items_to_assume_ownership_of_modifier =
                $set:
                  owner_id: perform_as
                  pending_owner_id: null

              APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(items_to_assume_ownership_of_modifier)
              {err, result} = JustdoHelpers.pseudoBlockingRawCollectionUpdateInsideFiber(APP.collections.Tasks, {_id: {$in: items_to_assume_ownership_of_actual}}, items_to_assume_ownership_of_modifier, {multi: true})

              if err?
                throw new Error err

          if items_to_cancel_ownership_transfer_of_provided
            items_to_cancel_ownership_transfer_of_set = new Set(data.items_to_cancel_ownership_transfer_of)
            items_to_cancel_ownership_transfer_of_actual = _.filter(items_ids, (item_id) -> items_to_cancel_ownership_transfer_of_set.has(item_id))

            if items_to_cancel_ownership_transfer_of_actual.length > 0
              items_to_cancel_ownership_transfer_of_modifier =
                $set:
                  pending_owner_id: null

              APP.projects._grid_data_com._addRawFieldsUpdatesToUpdateModifier(items_to_cancel_ownership_transfer_of_modifier)
              {err, result} = JustdoHelpers.pseudoBlockingRawCollectionUpdateInsideFiber(APP.collections.Tasks, {_id: {$in: items_to_cancel_ownership_transfer_of_actual}}, items_to_cancel_ownership_transfer_of_modifier, {multi: true})

              if err?
                throw new Error err

          return

      return # end of do =>

    return
