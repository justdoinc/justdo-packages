_.extend PACK.modules.direct_tasks,
  initServer: ->
    @_setupGridCondrolMiddlewares()

    @_setupMethods()

    return

  _setupGridCondrolMiddlewares: ->
    self = @

    new_item_middleware = (path, new_item_fields, perform_as) ->
      # Prevent new items from having _id equal to our 
      if (_id = new_item_fields._id)?
        if _id.substr(0, self.direct_tasks_prefix.length) == self.direct_tasks_prefix
          throw self._error("invalid-id")

      return true

    @_grid_data_com.setGridMethodMiddleware "addChild", new_item_middleware

    @_grid_data_com.setGridMethodMiddleware "addSibling", new_item_middleware

    return

  _setupMethods: ->
    self = @

    Meteor.methods
      newDirectTask: (target, task_fields) ->
        return self.newDirectTask(target, task_fields, @userId)

  newDirectTask: (target, task_fields, sending_user) ->
    # Adds a task to user's direct tasks list.
    #
    # On success, returns the created task id.
    #
    # Usage: 
    #
    # target: object of the following structure
    #
    #   {
    #     project_id: (string, required) the id of the project the task should belong to.
    #
    #     user_id: (string, required) the added task will be added to user_id's direct tasks.
    #       The created task will be accessible by the sending_user and user_id, that is,
    #       both will be its members, as defined by the task's `users` field.
    #       sending_user will be set as the task owner, and user_id will be set as its pending
    #       owner.
    #         * user_id must belong to project_id
    #         * user_id can be the sending_user, in such case the user will be the task owner
    #           with no ownership transfer process.
    #
    #     additional_task_members: (Array of strings, optional) list of user ids that will
    #       be added to the task's users field in addition to the sending_user and
    #       target.user_id.
    #         * All `additional_task_members` must belong to the project.
    #   }
    #
    # task_fields: Any field that is allowed by the task's schema.
    #              The following fields will be ignored: project_id, parents, users,
    #              seqId, owner, owner_id, pending_owner_id, pending_owner_updated_at.

    # DEVELOPER, Note, we are running all the addChild middlewares defined
    # for grid data com, there's no need to redefine their logic.

    #
    # Validations/Cleanups
    #

    # Validate target structure
    check target,
      project_id: String
      user_id: String
      additional_task_members: Match.Maybe([String])

    # Validate sending_user
    check sending_user, String
    project = @requireUserIsMemberOfProject target.project_id, sending_user

    # Validate target structure details
    target_users = [target.user_id, sending_user]
    if target.additional_task_members?
      target_users = target_users.concat(target.additional_task_members)
    target_users = _.uniq target_users

    project_members = project.members
    all_target_members_belong = _.every target_users, (user_id) ->
      for member in project_members
        if member.user_id == user_id
          return true

      return false

    if not all_target_members_belong
      throw @_error("unknown-members", "Some members ids provided for target.user_id or target.additional_task_members aren't part of the target project")

    # Validate task_fields

    # Shallow copy task_fields
    task_fields = _.extend {}, task_fields
    restricted_fields = ["project_id", "parents", "users", "seqId",
                         "owner_id", "pending_owner_id", "pending_owner_updated_at"]
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
    parent_id = "#{@direct_tasks_prefix}#{target.user_id}"
    new_task_order = @items_collection.getNewChildOrder(parent_id, task_fields)

    parents = {}
    parents[parent_id] =
      order: new_task_order
    task_fields.parents = parents

    # Set the new task users
    task_fields.users = target_users

    # Set owner
    task_fields.owner_id = sending_user

    if target.user_id != sending_user
      task_fields.pending_owner_id = target.user_id

    # seqid setting and other operations/validations are taken care by the addChild middlewares
    @_grid_data_com._runGridMethodMiddlewares "addChild", "/#{parent_id}/", task_fields, sending_user

    return @_grid_data_com._insertItem task_fields
