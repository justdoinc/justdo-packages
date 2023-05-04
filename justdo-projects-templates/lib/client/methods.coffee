_.extend JustDoProjectsTemplates.prototype,
  createSubtreeFromTemplate: (target_task, category_id, template_id, project_id, cb) ->
    Meteor.call "createSubtreeFromTemplate", target_task, category_id, template_id, project_id, cb
