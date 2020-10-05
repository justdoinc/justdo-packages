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
        # need to add code here trigger hook for recalculation here,
        # if the recalculation is moved to server side in the future, this piece of code should be removed
        if APP.justdo_planning_utilities.isPluginInstalledOnJustdo JD.activeJustdoId()
          result = APP.collections.Tasks.update task_id,
            $set:
              pending_owner_id: null
          
          if result != 1
            return 

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
              className: "ownership-hr-rejection-dialog"

              onEscape: ->
                complete()

                return true

              buttons:
                cancel:
                  label: "Cancel"

                  className: "btn-default"

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

  _setupHashRequests: ->
    self = @

    @hash_requests_handler.addRequestHandler "approve-ownership-transfer", (args) =>
      self._reactToOwnershipTransferHashRequest("approve", args)

      return

    @hash_requests_handler.addRequestHandler "reject-ownership-transfer", (args) =>
      self._reactToOwnershipTransferHashRequest("reject", args)

      return
