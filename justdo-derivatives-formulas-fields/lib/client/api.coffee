_.extend JustdoDerivativesFormulasFields.prototype,
  _immediateInit: ->
    @_projects_deriviatives_formulas_fields_applier_comp = Tracker.autorun (c) =>
      if not (current_project_id = JD.activeJustdo({_id: 1})?._id)?
        return 

      @installProjectFields(current_project_id)

      Tracker.onInvalidate =>
        @uninstallProjectFields(current_project_id)

      return

    @onDestroy =>
      @_projects_deriviatives_formulas_fields_applier_comp.stop()

      return

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  installProjectFields: (project_id) ->
    if (deriviatives_formulas_fields = JustdoDerivativesFormulasFields.deriviatives_formulas_fields?[project_id])?
      for deriviatives_formulas_field in deriviatives_formulas_fields
        APP.modules.project_page.setupPseudoCustomField deriviatives_formulas_field.field_id,
          label: deriviatives_formulas_field.field_label

          field_type: "number"
          decimal: true

          formatter: JustdoDerivativesFormulasFields.pseudo_field_formatter_id
          grid_dependencies_fields: deriviatives_formulas_field.dependencies_fields or []

          grid_column_formatter_options:
            formula: deriviatives_formulas_field.formula or (() -> return)

          grid_visible_column: true
          grid_editable_column: false
          default_width: 200

    return

  uninstallProjectFields: (project_id) ->
    if (deriviatives_formulas_fields = JustdoDerivativesFormulasFields.deriviatives_formulas_fields?[project_id])?
      for deriviatives_formulas_field in deriviatives_formulas_fields
        APP.modules.project_page.removePseudoCustomFields deriviatives_formulas_field.field_id

    return
