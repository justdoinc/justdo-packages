_.extend JustdoFormulaFields.prototype,
  setCustomFieldFormula: (project_id, custom_field_id, formula, cb) ->
    return Meteor.call "jdfSetCustomFieldFormula", project_id, custom_field_id, formula, cb
