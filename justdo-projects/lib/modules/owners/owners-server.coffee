_.extend PACK.modules.owners,
  initServer: ->
    @_setupMethods()
    @_setupCollectionsHooks()
    @_setupOwnersGridControlMiddlewares()

  _setupOwnersGridControlMiddlewares: ->
    new_item_middleware = (path, new_item_fields, perform_as) ->
      new_item_fields.owner_id = perform_as

      return true

    if Meteor.isServer
      @_grid_data_com.setGridMethodMiddleware "addChild", new_item_middleware

      @_grid_data_com.setGridMethodMiddleware "addSibling", new_item_middleware

    return

  _setupCollectionsHooks: ->
    self = @

    #
    # Send email notifying about ownership transfer
    #
    self.items_collection.after.update (userId, doc, fieldNames, modifier, options) ->
      if not (pending_owner_id = modifier?.$set?.pending_owner_id)?

        return

      prev_doc = @previous

      if pending_owner_id == prev_doc.pending_owner_id
        # Nothing changed, skip

        return

      owner_id = doc.owner_id

      Meteor.setTimeout ->
        doc_after_delay = self.items_collection.findOne(doc._id, {fields: {title: 1, seqId: 1, owner_id: 1, pending_owner_id: 1, project_id: 1}})

        if doc_after_delay.owner_id != owner_id or doc_after_delay.pending_owner_id != pending_owner_id
          # ownership transfer changed already, skip email sending

          # console.log "CHANGED, SKIP" # Keep for future testing

          return

        users_objects =
          Meteor.users.find({_id: {$in: [pending_owner_id, owner_id]}}).fetch()

        from = _.find users_objects, (user_doc) -> user_doc._id == owner_id
        to = _.find users_objects, (user_doc) -> user_doc._id == pending_owner_id

        if not from? or not to?
          throw self._error "user-not-exists", "user-not-exists"

          return

        task_id = doc_after_delay._id

        # Get the project 
        project_id = doc_after_delay.project_id
        # To avoid any chance that a user will get an email from a project
        # he isn't a member of we use self.requireUserIsMemberOfProject
        # since at the moment, the pending owner can be any user_id (no
        # checks are done on update), this is theoretically possible.
        project = self.requireUserIsMemberOfProject(project_id, to._id)

        # Send push notification
        if APP.justdo_push_notifications.isFirebaseEnabled()
          APP.justdo_push_notifications.pnUsersViaFirebase
            message_type: "owner-trans-req"

            body: "#{JustdoHelpers.displayName(from)} asks you to take ownership over task"

            recipients_ids: [to._id]

            networks: ["mobile"]

            data:
              project_id: project._id
              task_id: doc_after_delay._id

        if not self._isSubscribedToEmailNotifications(project_id, to)
          # User is not subscribed to email notifications

          # console.log "NO SUB" # Keep for future testing

          return

        # console.log "SEND EMAIL" # Keep for future testing

        APP.getEnv (env) =>
          base_link = "#{env.WEB_APP_ROOT_URL}/p/#{project_id}#&t=main"
          base_task_link = "#{base_link}&p=/#{task_id}/"

          contexts = self._grid_data_com.getContexts task_id, {}, pending_owner_id

          if _.isEmpty contexts
            str_context = ""
          else
            context = contexts[0] # Use the first context

            context.pop() # Rid of the item itself

            if context[0]._id == 0 # if full path to root pop the root part
              context.shift()

            str_context_arr =
              _.map context, (context_item) ->
                ret = ""

                if (seqId = context_item.seqId)?
                  ret += "##{context_item.seqId}"
                  if not _.isEmpty context_item.title
                    ret += ": "

                ret += "#{JustdoHelpers.xssGuard context_item.title}"
        
                return ret

            str_context = str_context_arr.join " > "

          JustdoEmails.buildAndSend
            to: JustdoHelpers.getUserMainEmail(to)
            template: "ownership-transfer"
            template_data:
              from: from
              to: to
              project: project
              task: doc_after_delay
              task_link: base_task_link
              accept_link: base_task_link + "&hr-id=approve-ownership-transfer&hr-project_id=#{project_id}&hr-task_id=#{task_id}&hr-pending_owner_id=#{pending_owner_id}"
              reject_link: base_task_link + "&hr-id=reject-ownership-transfer&hr-project_id=#{project_id}&hr-task_id=#{task_id}&hr-pending_owner_id=#{pending_owner_id}"
              unsubscribe_link: base_link + "&hr-id=unsubscribe-projects-email-notifications&hr-projects=#{project_id}"
              context: str_context
            subject: "#{project.title} - Ownership Transfer Request"
            # subject: JustdoHelpers.displayName(from) + " :: Task ownership transfer request"

      , 10 * 1000

      return


    #
    # Send email notifying about ownership transfer reject
    #
    self.items_collection.after.update (userId, doc, fieldNames, modifier, options) ->
      if not (reject_ownership_message_to = modifier?.$set?.reject_ownership_message_to)?
        return

      prev_doc = @previous

      if reject_ownership_message_to == prev_doc.reject_ownership_message_to
        # If the to doesn't change, we assume a message was sent already, skip

        return

      reject_ownership_message = doc.reject_ownership_message
      reject_ownership_message_by = doc.reject_ownership_message_by

      # console.log "REJECT", reject_ownership_message, reject_ownership_message_to, reject_ownership_message_by

      users_objects =
        Meteor.users.find({_id: {$in: [reject_ownership_message_by, reject_ownership_message_to]}}).fetch()

      from = _.find users_objects, (user_doc) -> user_doc._id == reject_ownership_message_by
      to = _.find users_objects, (user_doc) -> user_doc._id == reject_ownership_message_to

      if not from? or not to?
        throw self._error "user-not-exists", "user-not-exists"

        return

      task_id = doc._id
  
      # Send push notification
      if APP.justdo_push_notifications.isFirebaseEnabled()
        APP.justdo_push_notifications.pnUsersViaFirebase
          message_type: "owner-trans-dec"

          body: "#{JustdoHelpers.displayName(from)} rejected your ownership transfer request"

          recipients_ids: [to._id]

          networks: ["mobile"]

          data:
            project_id: doc.project_id
            task_id: doc._id

      # Get the project 
      project_id = doc.project_id
      # To avoid any chance that a user will get an email from a project
      # he isn't a member of we use self.requireUserIsMemberOfProject
      # since at the moment, the pending owner can be any user_id (no
      # checks are done on update), this is theoretically possible.
      project = self.requireUserIsMemberOfProject(project_id, to._id)

      if not self._isSubscribedToEmailNotifications(project_id, to)
        # User is not subscribed to email notifications

        # console.log "NO SUB" # Keep for future testing

        return

      # console.log "SEND EMAIL" # Keep for future testing

      APP.getEnv (env) =>
        base_link = "#{env.WEB_APP_ROOT_URL}/p/#{project_id}#&t=main"
        base_task_link = "#{base_link}&p=/#{task_id}/"

        JustdoEmails.buildAndSend
          to: JustdoHelpers.getUserMainEmail(to)
          template: "ownership-transfer-rejected"
          template_data:
            from: from
            to: to
            project: project
            task: doc
            task_link: base_task_link
            unsubscribe_link: base_link + "&hr-id=unsubscribe-projects-email-notifications&hr-projects=#{project_id}"

          subject: JustdoHelpers.displayName(from) + " :: Rejected ownership transfer"

      return

  _setupMethods: ->
    self = @

    Meteor.methods
      rejectOwnershipTransfer: (task_id, reject_message) ->
        if not reject_message?
          reject_message = ""
        
        check task_id, String
        check reject_message, String

        # Note, security, permssions, and other checks are done in the simple
        # schema level (incl. belonging to task and other checks)

        update =
          $set:
            reject_ownership_message: reject_message
            pending_owner_id: null

        self.items_collection.update(task_id, update, {removeEmptyStrings: false})

        return

      dismissOwnershipTransfer: (task_id) ->
        # We would avoid implementing this method, but we found it weird
        # to have an API for rejectOwnershipTransfer() and not for dismissing.
        #
        # In theory, unsetting the reject_ownership_message when attempting to
        # dismiss an ownership transfer, using the minimongo RPC call directly
        # is perfectly fine. (unlike rejectOwnershipTransfer which must be
        # called, discussion about that is in reject_ownership_message autoValue
        # comment)

        check task_id, String

        # Note, security, permssions, and other checks are done in the simple
        # schema level (incl. belonging to task and other checks)

        update = 
          $set:
            reject_ownership_message: null

        self.items_collection.update(task_id, update)

        return

    return