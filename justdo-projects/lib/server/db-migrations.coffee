# Keep here code used for db migrations

_.extend Projects.prototype,
  _setupDbMigrations: ->
    projects_object = @

    # **IMPORTANT** Unsecure - uncomment only when needed.
    # Meteor.methods
    #   addTasksSeqIndices: ->
    #     # Add to each task a seqId by order of creation (do nothing if already has seqID)
    #     projects_object.projects_collection.find({}).forEach (project) ->
    #       projects_object.items_collection.find({project_id: project._id}, {sort: {createdAt: 1}}).forEach (task) ->
    #         if not task.seqId?
    #           projects_object.items_collection.update task._id,
    #             $set:
    #               seqId: projects_object.allocateNewTaskSeqId project._id