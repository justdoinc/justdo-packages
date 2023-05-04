_.extend JustDoProjectsTemplates.prototype,
  createSubtreeFromTemplate: (category_id, template_id, project_id, cb) ->
    Meteor.call "createSubtreeFromTemplate", category_id, template_id, project_id, cb
