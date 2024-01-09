_.extend JustDoProjectsTemplates.prototype,
  createSubtreeFromTemplate: (target_task, template_id, project_id, cb) ->
    Meteor.call "createSubtreeFromTemplate", target_task, template_id, project_id, cb
  
  createSubtreeFromAiGeneratedTemplate: (options, cb) ->
    return Meteor.call "createSubtreeFromAiGeneratedTemplate", options, cb