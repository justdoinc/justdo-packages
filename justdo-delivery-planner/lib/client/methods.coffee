_.extend JustdoDeliveryPlanner.prototype,
  toggleTaskIsProject: (task_id, cb) ->
    Meteor.call "jdpToggleTaskIsProject", task_id, (err) ->
      if err?
        JustdoSnackbar.show
          text: "Operation rejected. #{err.reason}"
        console.error err
      return
      

  commitProjectPlan: (project_task_id, cb) ->
    Meteor.call "jdpCommitProjectPlan", project_task_id, cb

  removeProjectPlanCommit: (project_task_id, cb) ->
    Meteor.call "jdpRemoveProjectPlanCommit", project_task_id, cb

  getProjectBurndownData: (project_task_id, cb) ->
    Meteor.call "jdpGetProjectBurndownData", project_task_id, cb

  saveBaselineProjection: (task_id, data, cb) ->
    Meteor.call "jdpSaveBaselineProjection", task_id, data, cb

  removeBaselineProjection: (task_id, cb) ->
    Meteor.call "jdpRemoveBaselineProjection", task_id, cb
