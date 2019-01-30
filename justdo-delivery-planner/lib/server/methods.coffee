_.extend JustdoDeliveryPlanner.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      jdpToggleTaskIsProject: (task_id) ->
        check task_id, String

        return self.toggleTaskIsProject(task_id, @userId)

      jdpCommitProjectPlan: (project_task_id) ->
        check project_task_id, String

        return self.commitProjectPlan(project_task_id, @userId)

      jdpRemoveProjectPlanCommit: (project_task_id) ->
        check project_task_id, String

        return self.removeProjectPlanCommit(project_task_id, @userId)

      jdpGetProjectBurndownData: (task_id) ->
        check task_id, String

        return self.getProjectBurndownData(task_id, @userId)

      jdpSaveBaselineProjection: (task_id, data) ->
        check task_id, String
        check data, Object # thoroughly checked by saveBaselineProjection(). 

        return self.saveBaselineProjection task_id, data, @userId

      jdpRemoveBaselineProjection: (task_id) ->
        check task_id, String

        return self.removeBaselineProjection task_id, @userId

    return