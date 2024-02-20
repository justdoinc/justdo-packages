_.extend JustDoProjectsTemplates.prototype,
  createSubtreeFromTemplate: (target_task, template_id, project_id, cb) ->
    Meteor.call "createSubtreeFromTemplate", target_task, template_id, project_id, cb
  
  createSubtreeFromAiGeneratedTemplate: (options, cb) ->
    return Meteor.call "createSubtreeFromAiGeneratedTemplate", options, cb
  
  streamTemplateFromOpenAi: (msg, cb) ->
    return Meteor.call "streamTemplateFromOpenAi", msg, cb

  stopStreamTemplateFromOpenAi: (pub_id) ->
    return Meteor.call "stopStreamTemplateFromOpenAi", pub_id
  
  generateProjectTitleFromOpenAi: (msg, cb) ->
    return Meteor.call "generateProjectTitleFromOpenAi", msg, cb
  
  streamChildTasksFromOpenAi: (context, cb) ->
    return Meteor.call "streamChildTasksFromOpenAi", context, cb