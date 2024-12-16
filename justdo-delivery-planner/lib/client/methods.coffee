_.extend JustdoDeliveryPlanner.prototype,
  toggleTaskIsProject: (task_id, cb) ->
    Meteor.call "jdpToggleTaskIsProject", task_id, cb

    return
    
  setTaskProjectCollectionType: (task_id, type_id, cb) ->
    return Meteor.call "jdpSetTaskProjectCollectionType", task_id, type_id, cb

  unsetTaskProjectCollectionType: (task_id, cb) ->
    return Meteor.call "jdpUnsetTaskProjectCollectionType", task_id, cb

  toggleProjectsCollectionClosedState: (task_id, cb) ->
    return Meteor.call "jdpToggleProjectsCollectionClosedState", task_id, cb
