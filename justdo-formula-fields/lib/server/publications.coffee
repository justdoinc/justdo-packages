_.extend JustdoFormulaFields.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "jdfProjectFormulas", (project_id) -> # Note the use of -> not =>, we need @userId
      # Publishes all the formulas belonging to project_id, as long as @userId is a member of
      # project_id

      check project_id, String

      return self.projectFormulasPublicationHandler(@, project_id, @userId)

    return