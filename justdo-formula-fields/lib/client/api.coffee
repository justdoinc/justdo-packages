_.extend JustdoFormulaFields.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()
    # Smart Row Formula is considered a core custom field type.
    # We install it here so that it is available for all projects, 
    # regardless of whether the project has "JustdoFormulaFields" installed.
    @installSmartRowFormulaField()

    return

  setupCustomFeatureMaintainer: ->
    project_formulas_subscription_maintainer = null

    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoFormulaFields.project_custom_feature_id,
        installer: =>
          @installSmartFormulaCustomField()

          project_formulas_subscription_maintainer = Tracker.nonreactive ->
            return Tracker.autorun ->
              Meteor.subscribe "jdfProjectFormulas", APP.modules.project_page.curProj().id

              return

          return

        destroyer: =>
          @uninstallSmartFormulaCustomField()

          if project_formulas_subscription_maintainer?
            project_formulas_subscription_maintainer.stop()

            project_formulas_subscription_maintainer = null

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  installSmartFormulaCustomField: ->
    GridControlCustomFields.registerCustomFieldsTypes JustdoFormulaFields.custom_field_type_id,
      type_id: "number"
      label: "Formula"

      settings_button_template: "custom_field_conf_formula_field_editor_opener"

      custom_field_options:
        decimal: true
        grid_editable_column: false

    return

  uninstallSmartFormulaCustomField: ->
    GridControlCustomFields.unregisterCustomFieldsTypes JustdoFormulaFields.custom_field_type_id

    return

  installSmartRowFormulaField: ->
    GridControlCustomFields.registerCustomFieldsTypes JustdoFormulaFields.smart_row_formula_field_type_id,
      type_id: "number"
      label: "Smart Row Formula"
      label_i18n: "grid_control_custom_fields_smart_row_formula_label"
      settings_button_template: "smart_row_formula_editor_opener"
      custom_field_options:
        decimal: true
        grid_editable_column: false

    @onDestroy =>
      @uninstallSmartRowFormulaField()

      return

    return

  uninstallSmartRowFormulaField: ->
    GridControlCustomFields.unregisterCustomFieldsTypes JustdoFormulaFields.smart_row_formula_field_type_id
    return

  getCurrentGridControlObject: -> APP.modules.project_page.gridControl()

  getCurrentProjectCustomFields: ->
    return APP.modules.project_page.curProj()?.getProjectCustomFields()

  getCurrentProjectCustomFieldDefinition: (field_id) ->
    return current_field_def = _.find @getCurrentProjectCustomFields(), (custom_field) -> custom_field.field_id == field_id

  getFieldsAvailableForFormulasInCurrentLoadedProject: (formula_field_id, include_removed_fields=false, formula_type, grid_control) ->
    if not (gc = grid_control or @getCurrentGridControlObject())
      throw @_error "no-grid-control-loaded"

    all_fields = gc.getSchemaExtendedWithCustomFields(include_removed_fields)

    available_fields = []

    for field_id, field_def of all_fields
      field_def = _.extend {}, field_def # shallow copy

      field_def._id = field_id

      if field_def._id is formula_field_id
        # Can't add itself!
        continue

      if not @_isFieldAvailableForFormulas(field_def, formula_type)
        continue

      if (custom_field_def = @getCurrentProjectCustomFieldDefinition(field_def._id))?
        # If field is a custom field, we have some extra rules.

        try
          @throwErrorIfNotAllowedCustomFieldDef(custom_field_def, formula_type)
        catch e
          continue

      available_fields.push field_def

    return available_fields

  getHumanReadableFormulaForCurrentLoadedProject: (formula, formula_field_id, formula_type, grid_control) ->
    available_fields_including_removed =
      @getFieldsAvailableForFormulasInCurrentLoadedProject(formula_field_id, true, formula_type, grid_control)

    human_readable_formula = formula.replace JustdoFormulaFields.formula_fields_components_matcher_regex, (a, b) ->
      field_def = _.find available_fields_including_removed, (field_def) -> field_def._id == b

      if not field_def?
        field_label = b # Just leave as is.
      else
        field_label = field_def.label

      return "{" + field_label + "}"

    human_readable_formula = @removeRedundantSpacesFormula(human_readable_formula)

    return human_readable_formula

  getFormulaFromHumanReadableFormulaForCurrentLoadedProject: (human_readable_formula, formula_field_id, formula_type=JustdoFormulaFields.custom_field_type_id, cb) ->
    available_fields_including_removed =
      @getFieldsAvailableForFormulasInCurrentLoadedProject(formula_field_id, true, formula_type)

    try
      formula = human_readable_formula.replace JustdoFormulaFields.formula_human_readable_fields_components_matcher_regex, (a, b) =>
        field_def = _.find available_fields_including_removed, (field_def) -> field_def.label == b

        if not field_def?
          throw @_error "human-readable-field-match-failed", "Field {#{b}} can't be found or not available for use in formulas."
        else
          field_id = field_def._id

        return "{" + field_id + "}"
    catch e
      return cb(e)

    formula = @removeRedundantSpacesFormula(formula)

    try
      # We process the formula in this stage, to ensure no exception is raised (consider this
      # step as validation testing).
      processed_formula_result = @processFormula(formula, formula_field_id, APP.modules.project_page.curProj().getProjectCustomFields(), {formula_type: formula_type})
    catch e
      return cb(e)

    return cb(undefined, formula)

  getHumanReadableFormula: (field_id, grid_control) ->
    field_def = @getCurrentProjectCustomFieldDefinition(field_id)
    formula_type = field_def?.custom_field_type_id

    if @isSmartRowFormulaField formula_type
      formula = field_def?.field_options?.formula or ""
    else
      formula = APP.collections.Formulas.findOne({custom_field_id: field_id})?.formula or ""

    if not _.isEmpty(formula)
      return @getHumanReadableFormulaForCurrentLoadedProject(formula, field_id, formula_type, grid_control)

    return ""

  showFormulaEditingRulesDialog: ->
    data = {}

    message_template =
      JustdoHelpers.renderTemplateInNewNode(Template.justdo_formula_fields_editing_rules, data)

    dialog = bootbox.dialog
      title: "Writing a Formula"
      message: message_template.node
      className: "formula-editing-rules-dialog bootbox-new-design"
      rtl_ready: true

      onEscape: ->
        return true

      buttons:
        close:
          label: "Close"

          className: "btn-primary"

          callback: ->
            return true

    return

  getSmartRowFormulaDependencies: (formula) ->
    # Get the direct dependencies of a smart row formula
    # Returns an array of field IDs
    if not formula? or _.isEmpty(formula)
      return []

    {field_to_symbol} = @replaceFieldsWithSymbols(formula)

    return _.keys(field_to_symbol)

  getFlattenedDependencies: (field_id, custom_fields, visited_fields=null) ->
    # Recursively find all dependencies for a smart row formula field,
    # including dependencies of nested smart row formula fields.
    #
    # Arguments:
    #   field_id: The field ID to find dependencies for
    #   custom_fields: Array of custom field definitions
    #   visited_fields: Set of already visited field IDs (for cycle detection)
    #
    # Returns:
    #   Array of unique field IDs that this field depends on (directly or indirectly)

    if not visited_fields?
      visited_fields = {}

    # Prevent infinite loops from circular dependencies
    if field_id of visited_fields
      return []

    visited_fields[field_id] = true

    field_def = _.find custom_fields, (cf) -> cf.field_id is field_id

    if not field_def?
      return []

    direct_dependencies = @getSmartRowFormulaDependencies(field_def.field_options?.formula)

    if _.isEmpty(direct_dependencies)
      return []

    all_dependencies = []

    for dep_field_id in direct_dependencies
      # Add the direct dependency
      all_dependencies.push dep_field_id

      # Check if the dependency is also a smart row formula
      dep_field_def = _.find custom_fields, (cf) -> cf.field_id is dep_field_id

      if @isSmartRowFormulaField(dep_field_def?.custom_field_type_id)
        # Recursively get its dependencies
        nested_dependencies = @getFlattenedDependencies(dep_field_id, custom_fields, visited_fields)
        all_dependencies = all_dependencies.concat(nested_dependencies)

    # Return unique dependencies, excluding the field itself
    return _.uniq(_.without(all_dependencies, field_id))

  getFieldsDependingOnField: (target_field_id, custom_fields) ->
    # Find all smart row formula fields that depend on the given field
    # (either directly or through nested smart row formula dependencies)
    #
    # Arguments:
    #   target_field_id: The field ID to check for dependents
    #   custom_fields: Array of custom field definitions
    #
    # Returns:
    #   Array of field IDs that depend on target_field_id

    dependent_field_ids = []

    for field_def in custom_fields
      if not @isSmartRowFormulaField(field_def.custom_field_type_id)
        continue

      if field_def.field_id is target_field_id
        continue

      # Get the current flattened dependencies for this field
      flattened_deps = @getFlattenedDependencies(field_def.field_id, custom_fields)

      if target_field_id in flattened_deps
        dependent_field_ids.push field_def.field_id

    return dependent_field_ids

  updateDependenciesForField: (field_id, custom_fields) ->
    # Update grid_dependencies_fields for a smart row formula field
    # with the flattened dependencies (including nested dependencies)
    #
    # Arguments:
    #   field_id: The field ID to update dependencies for
    #   custom_fields: Array of custom field definitions (will be modified in place)
    #
    # Returns:
    #   true if dependencies were updated, false otherwise

    field_def = _.find custom_fields, (cf) -> cf.field_id is field_id

    if not field_def?
      return false

    if not @isSmartRowFormulaField(field_def.custom_field_type_id)
      return false

    flattened_deps = @getFlattenedDependencies(field_id, custom_fields)

    if not _.isEmpty(flattened_deps)
      field_def.grid_dependencies_fields = flattened_deps
    else
      delete field_def.grid_dependencies_fields

    return true

  updateDependentFieldsDependencies: (changed_field_id, custom_fields) ->
    # Update dependencies for all smart row formula fields that depend on the changed field.
    # This should be called after a field's formula or dependencies change.
    #
    # Arguments:
    #   changed_field_id: The field ID that was changed
    #   custom_fields: Array of custom field definitions (will be modified in place)
    #
    # Returns:
    #   Array of field IDs that were updated

    updated_field_ids = []

    dependent_field_ids = @getFieldsDependingOnField(changed_field_id, custom_fields)

    for dep_field_id in dependent_field_ids
      if @updateDependenciesForField(dep_field_id, custom_fields)
        updated_field_ids.push dep_field_id

    return updated_field_ids
