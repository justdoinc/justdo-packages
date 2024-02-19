_.extend JustDoProjectsTemplates.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      createSubtreeFromTemplate: (target_task, template_id, project_id) ->
        check template_id, String
        check project_id, String
        check @userId, String

        template = self.requireTemplateById(template_id).template

        options =
          template_id: template_id
          template: template
          project_id: project_id
          root_task_id: target_task
          users:
            performing_user: @userId
          perform_as: "performing_user"

        return APP.justdo_projects_templates.createSubtreeFromTemplateUnsafe options

      createSubtreeFromAiGeneratedTemplate: (options) ->
        # Options are throughly checked inside createSubtreeFromOpenAi
        check options, Object
        check @userId, String
        return self.createSubtreeFromOpenAi options, @userId
      
      generateTemplateFromOpenAi: (msg) ->
        check msg, String
        check @userId, String # login required
        res = await self.generateTemplateFromOpenAi(msg)
        return JSON.parse(res?.choices?[0]?.message?.content)
      
      streamTemplateFromOpenAi: (msg) ->
        # Checking of msg is done inside streamTemplateFromOpenAiMethodHandler
        if _.isString msg
          msg = {msg}
        check @userId, String # login required
        return self.streamTemplateFromOpenAiMethodHandler(msg, @userId)
      
      stopStreamTemplateFromOpenAi: (pub_id) ->
        check pub_id, String
        check @userId, String
        self.emit "stop_stream_#{pub_id}_#{@userId}"
        return

    return
