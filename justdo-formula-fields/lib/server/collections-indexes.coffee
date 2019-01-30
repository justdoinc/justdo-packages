_.extend JustdoFormulaFields.prototype,
  _ensureIndexesExists: ->
    # FETCH_PROJECT_SPECIFIC_FORMULA_INDEX
    @formulas_collection._ensureIndex {"project_id": 1, "custom_field_id": 1}, {unique: true}

    # FETCH_PROJECT_ALL_FORMULAS_INDEX
    @formulas_collection._ensureIndex {"project_id": 1}

    # FETCH_PROJECT_ACTIVE_FORMULAS_INDEX
    @formulas_collection._ensureIndex
      project_id: 1
      formula: 1
      formula_dependent_fields_array: 1
      defect_found: 1
      project_removed: 1
      plugin_disabled: 1
      formula_field_removed: 1
    , {name: "fetch_project_active_formulas_index"}

    return