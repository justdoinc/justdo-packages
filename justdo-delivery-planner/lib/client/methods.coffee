_.extend JustdoDeliveryPlanner.prototype,
  toggleTaskIsProject: (task_id, cb) ->
    Meteor.call "jdpToggleTaskIsProject", task_id, cb

    return
    
  toggleTaskAsProjectsCollection: (task_id, cb) ->
    return Meteor.call "jdpToggleTaskAsProjectsCollection", task_id, cb

  toggleProjectsCollectionClosedState: (task_id, cb) ->
    return Meteor.call "jdpToggleProjectsCollectionClosedState", task_id, cb
