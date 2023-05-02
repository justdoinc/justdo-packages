_.extend JustdoNewProjectTemplates.prototype,
  createSubtreeFromTemplate: (template_id, project_id, cb) ->
    Meteor.call "createSubtreeFromTemplate", template_id, project_id, cb
