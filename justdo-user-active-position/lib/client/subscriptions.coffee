_.extend JustdoUserActivePosition.prototype,
  subscribeToProjectMembersCurrentPositions: (project_id) ->
    Meteor.subscribe "projectMembersCurrentPositions", project_id

    return
