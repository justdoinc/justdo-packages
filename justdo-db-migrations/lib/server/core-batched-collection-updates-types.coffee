_.extend JustdoDbMigrations.prototype,
  _registerCoreCollectionUpdatesTypes: ->
    self = @

    do => # To avoid job_type from mixing with the next one.
      membersProvided = (data) ->
        members_to_add_provided = data?.members_to_add? and not _.isEmpty(data.members_to_add)
        members_to_remove_provided = data?.members_to_remove? and not _.isEmpty(data.members_to_remove)

        return {members_to_add_provided, members_to_remove_provided}

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

        jobsGatekeeper: (options) ->
          {data, ids_to_update, user_id} = options

          APP.projects.requireUserIsMemberOfProject data.project_id, user_id

          {members_to_add_provided, members_to_remove_provided} = membersProvided(data)

          if not members_to_add_provided and not members_to_remove_provided
            throw self._error "invalid-job-data", "For jobs of type #{job_type} at least one of the fields members_to_add/members_to_remove should be provided in the job's data object (and be non-empty)"
          
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
          {members_to_add_provided, members_to_remove_provided} = membersProvided(data)

          if members_to_add_provided
            APP.projects._grid_data_com._setPrivateDataDocsFreezeState(data.members_to_add, items_ids, false)
            # Important, if you change the logic here, note that in the process of inviteMember
            # we also call @_setPrivateDataDocsFreezeState()

            APP.projects._grid_data_com._removeIsRemovedOwnerForTasksBelongingTo(items_ids, data.members_to_add)

          if members_to_remove_provided
            APP.projects._grid_data_com._setPrivateDataDocsFreezeState(data.members_to_remove, items_ids, true)
            # Important, if you change the logic here, note that in the process of removeMember
            # we do something similar using a slight different API: _freezeAllProjectPrivateDataDocsForUsersIds

          return

      return # end of do =>

    return

# items_to_assume_ownership_of:
#   type: [String]
#   optional: true
# items_to_cancel_ownership_transfer_of:
#   type: [String]
#   optional: true

# if not _.isEmpty members_to_remove
#   members_remove_modifier =
#     $pull:
#       users:
#         $in: members_to_remove

# if not _.isEmpty members_to_add
#   members_add_modifier =
#     $push:
#       users:
#         $each: members_to_add

#   project.bulkUpdate items_to_edit, members_add_modifier

# if not _.isEmpty items_to_assume_ownership_of
#   ownership_update_modifier =
#     $set:
#       owner_id: Meteor.userId()
#       pending_owner_id: null

#   project.bulkUpdate items_to_assume_ownership_of, ownership_update_modifier

# if not _.isEmpty items_to_cancel_ownership_transfer_of
#   ownership_transfer_cancel_modifier =
#     $set:
#       pending_owner_id: null

# console.log "WE ARE HERE", {data, perform_as}