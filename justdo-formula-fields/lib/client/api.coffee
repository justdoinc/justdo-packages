_.extend JustdoFormulaFields.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  setupCustomFeatureMaintainer: ->
    project_formulas_subscription_maintainer = null

    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoFormulaFields.project_custom_feature_id,
        installer: =>
          @installCustomField()

          project_formulas_subscription_maintainer = Tracker.nonreactive ->
            return Tracker.autorun ->
              Meteor.subscribe "jdfProjectFormulas", APP.modules.project_page.curProj().id

              return

          return

        destroyer: =>
          @uninstallCustomField()

          if project_formulas_subscription_maintainer?
            project_formulas_subscription_maintainer.stop()

            project_formulas_subscription_maintainer = null

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  installCustomField: ->
    GridControlCustomFields.registerCustomFieldsTypes JustdoFormulaFields.custom_field_type_id, 
      type_id: "number"
      label: "Formula"

      settings_button_template: "custom_field_conf_formula_field_editor_opener"

      custom_field_options:
        decimal: true
        grid_editable_column: false

    return

  uninstallCustomField: ->
    GridControlCustomFields.unregisterCustomFieldsTypes JustdoFormulaFields.custom_field_type_id

    return

  getCurrentGridControlObject: -> APP.modules.project_page.gridControl()

  getCurrentProjectCustomFields: ->
    return APP.modules.project_page.curProj()?.getProjectCustomFields()

  getCurrentProjectCustomFieldDefinition: (field_id) ->
    return current_field_def = _.find @getCurrentProjectCustomFields(), (custom_field) -> custom_field.field_id == field_id

  getFieldsAvailableForFormulasInCurrentLoadedProject: (formula_field_id, include_removed_fields=false) ->
    if not (gc = @getCurrentGridControlObject())
      throw @_error "no-grid-control-loaded"

    all_fields = gc.getSchemaExtendedWithCustomFields(include_removed_fields)

    available_fields = []

    for field_id, field_def of all_fields
      field_def = _.extend {}, field_def # shallow copy

      field_def._id = field_id

      if JustdoFormulaFields.forbidden_fields_suffixes_regex.test(field_def._id)
        continue

      if not JustdoFormulaFields.allowed_field_names_chars_pattern_regex.test(field_def._id)
        continue

      if field_def.type not in JustdoFormulaFields.supported_fields_types
        continue

      if not field_def.grid_visible_column
        continue

      if field_def._id == formula_field_id
        # Can't add itself!
        continue

      if field_def._id of JustdoFormulaFields.forbidden_fields
        continue

      if (custom_field_def = @getCurrentProjectCustomFieldDefinition(field_def._id))?
        # If field is a custom field, we have some extra rules.

        try
          @throwErrorIfNotAllowedCustomFieldDef(custom_field_def)
        catch e
          continue

      available_fields.push field_def

    return available_fields

  getHumanReadableFormulaForCurrentLoadedProject: (formula, formula_field_id) ->
    available_fields_including_removed =
      @getFieldsAvailableForFormulasInCurrentLoadedProject(formula_field_id, true)

    human_readable_formula = formula.replace JustdoFormulaFields.formula_fields_components_matcher_regex, (a, b) ->
      field_def = _.find available_fields_including_removed, (field_def) -> field_def._id == b

      if not field_def?
        field_label = b # Just leave as is.
      else
        field_label = field_def.label

      return "{" + field_label + "}"

    human_readable_formula = @removeRedundantSpacesFormula(human_readable_formula)

    return human_readable_formula

  getFormulaFromHumanReadableFormulaForCurrentLoadedProject: (human_readable_formula, formula_field_id, cb) ->
    available_fields_including_removed =
      @getFieldsAvailableForFormulasInCurrentLoadedProject(formula_field_id, true)

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
      processed_formula_result = @processFormula(formula, formula_field_id, APP.modules.project_page.curProj().getProjectCustomFields())
    catch e
      return cb(e)

    return cb(undefined, formula)

  showFormulaEditingRulesDialog: ->
    data = {}

    message_template =
      JustdoHelpers.renderTemplateInNewNode(Template.justdo_formula_fields_editing_rules, data)

    dialog = bootbox.dialog
      title: "Writing a Formula"
      message: message_template.node
      className: "formula-editing-rules-dialog bootbox-new-design"

      onEscape: ->
        return true

      buttons:
        close:
          label: "Close"

          className: "btn-primary"

          callback: ->
            return true

    return
