_.extend JustDoProjectsTemplates.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      createSubtreeFromTemplate: (category_id, template_id, project_id) ->
        check category_id, String
        check template_id, String
        check project_id, String
        check @userId, String

        if not (template = self.project_templates?[category_id]?[template_id])?
          throw self._error "template-not-found"

        APP.justdo_projects_templates.createSubtreeFromTemplateUnsafe
          template: template
          project_id: project_id
          users:
            performing_user: @userId
          perform_as: "performing_user"

        return

    return
