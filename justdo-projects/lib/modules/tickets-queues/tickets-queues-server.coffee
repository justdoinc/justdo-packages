_.extend PACK.modules.tickets_queues,
  initServer: ->
    @tickets_queue_local_collection_name = @options.local_tickets_queue_collection_name

    @_setupPublication()

    @_setupMethods()

    @_setupIndices()

    return

  _setupPublication: ->
    self = @

    Meteor.publish "projectsTicketsQueues", (project_id) -> # Note the use of -> not =>, we need @userId
      tickets_queues_tracker = null
      self.projectMembershipRequirementPubManager @, project_id,
        success: ->
          tracker_query =
            project_id: project_id
            is_tickets_queue: true

          tracker_query_options =
            fields:
              _id: 1
              seqId: 1
              title: 1
              owner_id: 1
              users: 1
              project_id: 1

          tickets_queues_tracker = self.items_collection.find(tracker_query, tracker_query_options).observeChanges
            added: (id, fields) =>
              @added self.tickets_queue_local_collection_name, id, fields

            changed: (id, fields) =>
              @changed self.tickets_queue_local_collection_name, id, fields

            removed: (id) =>
              @removed self.tickets_queue_local_collection_name, id

        stop: ->
          tickets_queues_tracker.stop()

      return # undefined

  _setupMethods: ->
    self = @

    Meteor.methods
      newTQTicket: (target, task_fields) ->
        return self.newTicket(target, task_fields, @userId)

  newTicket: (target, task_fields, user_id) ->
    # Adds a task to a tickets queue.
    #
    # On success, returns the created task id.
    #
    # Usage: 
    #
    # target: object of the following structure
    #
    #   {
    #     project_id: (string, required) the id of the project the task should belong to.
    #     tq: (string, required) the ticket queue task _id.
    #   }
    #
    # task_fields: Any field that is allowed by the task's schema.
    #              The following fields will be ignored: project_id, parents, users,
    #              seqId, owner, owner_id, pending_owner_updated_at.

    # DEVELOPER, Note, we are running all the addChild middlewares defined
    # for grid data com, there's no need to redefine their logic.

    #
    # Validations/Cleanups
    #

    # Validate target structure
    check target,
      project_id: String
      tq: String

    # Validate user_id
    check user_id, String
    project = @requireUserIsMemberOfProject target.project_id, user_id

    tq = @_grid_data_com.collection.findOne(target.tq, {fields: {_id: 1, users: 1}})

    if not tq?
      throw new Meteor.Error("unknown-ticket-queue", "Ticket Queue #{target.tq} unknown")

    # Validate task_fields

    # Shallow copy task_fields
    task_fields = _.extend {}, task_fields
    restricted_fields = ["project_id", "parents", "users", "seqId",
                         "owner_id", "pending_owner_updated_at"]
    # Note, further restrictions are set in the tasks Schema
    for restricted_field in restricted_fields
      delete task_fields[restricted_field]

    #
    # Set task details
    #

    # Set project_id
    task_fields.project_id = target.project_id # Must be set before finding correct task order under user's direct tasks

    # Set parents

    # Note that by this point task_fields.project_id must be set !
    parent_id = target.tq
    new_task_order = @items_collection.getNewChildOrder(parent_id, task_fields, {limit_to_task_project_id: true})

    parents = {}
    parents[parent_id] =
      order: new_task_order
    task_fields.parents = parents

    # Set the new task users
    target_users = _.uniq(tq.users.concat(user_id))
    task_fields.users = target_users

    # Set owner
    task_fields.owner_id = user_id

    APP.justdo_permissions.runCbInIgnoredPermissionsScope =>
      # seqid setting and other operations/validations are taken care by the addChild middlewares
      @_grid_data_com._runGridMethodMiddlewares "addChild", "/#{parent_id}/", task_fields, user_id

      return

    return @_grid_data_com._insertItem task_fields

  _setupIndices: ->
    @items_collection._ensureIndex {"is_tickets_queue": 1, "project_id": 1}