JustdoHelpers.hooks_barriers.runCbAfterBarriers "justdo-formula-fields-init", ->
  project_page_module = APP.modules.project_page

  #
  # Editor opener
  #
  Template.smart_row_formula_editor_opener.onCreated ->
    @formula_editor = null

    return

  Template.smart_row_formula_editor_opener.onRendered ->
    template_data = _.extend {}, @data,
      formula_type: JustdoFormulaFields.smart_row_formula_field_type_id

    @formula_editor = new project_page_module.CustomFieldFormulaFieldEditor(@firstNode, template_data)

    return

  Template.smart_row_formula_editor_opener.onDestroyed ->
    if @formula_editor?
      @formula_editor.destroy()
      @formula_editor = null

    return
