_.extend JustdoNewProjectTemplates.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      createSubtreeFromTemplate: (template_id, project_id) ->
        check template_id, String
        check project_id, String
        check @userId, String

        if not (template = self.project_templates[template_id])?
          throw self._error "template-not-found"

        APP.justdo_projects_templates.createSubtreeFromTemplateUnsafe
          template: template
          project_id: project_id
          users:
            manager: @userId
          perform_as: "manager"

        return

    return
