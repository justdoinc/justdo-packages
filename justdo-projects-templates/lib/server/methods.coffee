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
          template: template
          project_id: project_id
          root_task_id: target_task
          users:
            performing_user: @userId
          perform_as: "performing_user"

        return APP.justdo_projects_templates.createSubtreeFromTemplateUnsafe options

    return
