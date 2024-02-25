_.extend JustDoProjectsTemplates.prototype,
  createSubtreeFromTemplate: (target_task, template_id, project_id, cb) ->
    Meteor.call "createSubtreeFromTemplate", target_task, template_id, project_id, cb
  
  generateProjectTitleFromOpenAi: (msg, cb) ->
    return Meteor.call "generateProjectTitleFromOpenAi", msg, cb
