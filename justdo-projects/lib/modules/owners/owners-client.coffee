_.extend PACK.modules.owners,
  initClient: ->
    @_setupMethods()
    @_setupHashRequests()

    return

  _setupMethods: ->
    self = @

    _.extend @,
      rejectOwnershipTransfer: (task_id, reject_message) ->
        # XXX As the recalculation of duration caused by ownership transfer is done on the client side at this point,
        # need to add code here do recalculation here,
        # if the recalculation is moved to server side in the future, this piece of code should be removed
        if APP.justdo_planning_utilities?.isPluginInstalledOnJustdo(JD.activeJustdoId()) and
            (task = APP.collections.Tasks.findOne(task_id, {fields: undefined}))? # If task can't be found in mini-mongo, it is likely in a different JustDo hence, no need to update any pseudo fields related to planning utilities

          recal = APP.justdo_planning_utilities.createDatesRecalculation()
          set_values = recal.getRecalculatedDatesAndDuration task_id,
            pending_owner_id: null
          
          delete set_values.pending_owner_id
          
          for field, new_val of set_values
            if new_val != task[field]
              APP.collections.Tasks.update task_id,
                $set: set_values
              break


        Meteor.call "rejectOwnershipTransfer", task_id, reject_message

        return 

      dismissOwnershipTransfer: (task_id) ->
        Meteor.call "dismissOwnershipTransfer", task_id

        return 

    return

  _reactToOwnershipTransferHashRequest: (type, args) ->
    if type not in ["approve", "reject"]
      @logger.warn "_reactToOwnershipTransferHashRequest: unknown type #{type} skipping"

      return

    {project_id, task_id, pending_owner_id} = args

    if not project_id? or not task_id? or not pending_owner_id?
      @logger.warn "_reactToOwnershipTransferHashRequest: not all required argument provided"

      return 

    check project_id, String
    check task_id, String
    check pending_owner_id, String

    project_subscription = APP.projects.requireProjectTasksSubscription(project_id)

    APP.projects.awaitProjectFirstDdpSyncReadyMsg project_id, =>
      Tracker.nonreactive =>
        Tracker.autorun (c) =>
          complete = ->
            project_subscription.stop()
            c.stop()

            return

          if project_subscription.ready()
            if not (task = @items_collection.findOne(task_id))?
              bootbox.alert("Couldn't find the task to #{type}.")

              complete()

              return

            if pending_owner_id != task.pending_owner_id
              # If the user is no longer the pending owner, do nothing.
              complete()

              # Present an alert notifying the user that the task is no longer pending transfer only
              # when the user wants to approve the ownership transfer, and isn't the current owner
              # alredady.
              if type == "approve" and Meteor.userId() != task.owner_id
                bootbox.alert("Task ##{task.seqId} is no longer pending transfer to you.")



              return

            if type == "approve"
              update = 
                $set:
                  owner_id: Meteor.userId()
                  pending_owner_id: null

              @items_collection.update(task_id, update)

              bootbox.alert("Ownership transfer of task ##{task.seqId} approved.")

              complete()

              return
            else
              data =
                task: @items_collection.findOne(task_id)

              message_template =
                APP.helpers.renderTemplateInNewNode(Template.ownership_rejection_hash_request_bootbox, data)

              bootbox.dialog
                title: "Reject Ownership Transfer"
                message: message_template.node
                className: "ownership-hr-rejection-dialog bootbox-new-design"

                onEscape: ->
                  complete()

                  return true

                buttons:
                  cancel:
                    label: "Cancel"

                    className: "btn-light"

                    callback: ->
                      complete()

                      return true

                  continue:
                    label: "Send"

                    callback: =>
                      reject_message = $(".hr-ownership-rejection-message").val()

                      APP.projects.modules.owners.rejectOwnershipTransfer(task_id, reject_message)

                      complete()

                      return true



              return

            return 
      return
    return

  _setupHashRequests: ->
    self = @

    @hash_requests_handler.addRequestHandler "approve-ownership-transfer", (args) =>
      self._reactToOwnershipTransferHashRequest("approve", args)

      return

    @hash_requests_handler.addRequestHandler "reject-ownership-transfer", (args) =>
      self._reactToOwnershipTransferHashRequest("reject", args)

      return
  
  takeOwnership: (task_id, new_owner_id) ->
    check task_id, String
    check new_owner_id, String

    task_doc = APP.collections.Tasks.findOne(task_id, {fields: {project_id: 1, owner_id: 1, include_descendants_upon_ownerhsip_transfer: 1, limit_owners_upon_decedants_ownerhsip_transfer: 1}})
    if not task_doc?
      return
    
    project_id = task_doc.project_id
    include_descendants_upon_ownerhsip_transfer = task_doc.include_descendants_upon_ownerhsip_transfer
    limit_owners_upon_decedants_ownerhsip_transfer = task_doc.limit_owners_upon_decedants_ownerhsip_transfer
    
    affected_task_ids = []
    if task_doc.owner_id isnt new_owner_id
      affected_task_ids.push task_id

    # Taking ownerhsip of a single task can be done by just updating the task owner
    if not include_descendants_upon_ownerhsip_transfer
      query = 
        _id: task_id
      modifier = 
        $set: 
          owner_id: new_owner_id
          pending_owner_id: null
          is_removed_owner: null
          include_descendants_upon_ownerhsip_transfer: null
          limit_owners_upon_decedants_ownerhsip_transfer: null
      
      APP.collections.Tasks.update query, modifier
      return affected_task_ids

    grid_data = APP.modules.project_page.mainGridData()
    path = grid_data.getCollectionItemIdPath task_id
    grid_data.each path, (section, item_type, item_obj) ->
      item_owner_id = item_obj.owner_id
      # Already owned by the new owner, no need to update
      if item_owner_id is new_owner_id
        return
      
      # If limit_owners_upon_decedants_ownerhsip_transfer is set, the item must be owned by one of the limit owners
      is_item_owned_by_limit_owners = true
      if not _.isEmpty task_doc.limit_owners_upon_decedants_ownerhsip_transfer
        is_item_owned_by_limit_owners = item_owner_id in task_doc.limit_owners_upon_decedants_ownerhsip_transfer
      
      if not is_item_owned_by_limit_owners
        return
      
      affected_task_ids.push item_obj._id

      return
    
    if not _.isEmpty affected_task_ids
      @bulkUpdateTasksOwner project_id, task_id, affected_task_ids, new_owner_id

    return affected_task_ids
  
  bulkUpdateTasksOwner: (project_id, common_parent_id, task_ids, new_owner_id) ->
    check task_ids, [String]
    check new_owner_id, String

    Meteor.call "bulkUpdateTasksOwner", project_id, common_parent_id, task_ids, new_owner_id, (err) ->
      if err?
        JustdoSnackbar.show
          text: err.message

    return