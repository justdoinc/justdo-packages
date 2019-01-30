_.extend JustdoFormulaFields.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      jdfSetCustomFieldFormula: (project_id, custom_field_id, formula) ->
        check project_id, String
        check custom_field_id, String
        check formula, Match.Maybe(String)

        self.setCustomFieldFormula(project_id, custom_field_id, formula, {}, @userId)

        return

    return
