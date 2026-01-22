APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  project_page_module.SmartRowFormulaEditor = JustdoHelpers.generateNewTemplateDropdown "smart-row-formula-editor", "smart_row_formula_editor",
    custom_dropdown_class: "dropdown-menu shadow-lg border-0 p-3"
    custom_bound_element_options:
      close_button_html: null

      keep_open_while_bootbox_active: false

      close_on_esc: false

      container: ".modal-content"

      close_on_context_menu_outside: false
      close_on_click_outside: false
      close_on_mousedown_outside: false
      close_on_bound_elements_show: false

      close_on_bootstrap_dropdown_show: false

      openedHandler: ->
        # The bootbox's modal is set with tabindex=-1 attr, that prevents the inputs on the bound
        # element from being focusable. We therefore remove here the tabindex attribute.

        $('[tabindex="-1"]').removeAttr("tabindex")

        @controller_template_scroll_handler = =>
          @$dropdown.data("updatePosition")()

          return
        $(".controller-template").on "scroll", @controller_template_scroll_handler

        @project_configuration_dialog_scroll_handler = =>
          @$dropdown.data("updatePosition")()

          return
        $(".project-configuration-dialog").on "scroll", @project_configuration_dialog_scroll_handler

        # We want the user to have to use the save/cancel button, and prevent accidental close of
        # the editor.
        @$dropdown.data("preventDropdownClose")()

        return

      closedHandler: ->
        $(".controller-template").off "scroll", @controller_template_scroll_handler
        $(".project-configuration-dialog").off "scroll", @project_configuration_dialog_scroll_handler

        return

    updateDropdownPosition: ($connected_element) ->
      @$dropdown
        .position
          of: $connected_element
          my: "left top"
          at: "left bottom"
          collision: "fit fit"
          using: (new_position, details) =>
            target = details.target
            element = details.element

            element.element.css
              top: new_position.top + 2
              left: new_position.left - 3

  #
  # Editor opener
  #
  Template.smart_row_formula_editor_opener.onCreated ->
    @formula_editor = null

    return

  # XXX Not the perfect way to pass data, but quick workaround to the level of complexity
  # the bound element mechanisems reached, Daniel C.
  current_rendering_field_id = null
  Template.smart_row_formula_editor_opener.onRendered ->
    $(@firstNode).click =>
      current_rendering_field_id = @data.field_id

    @formula_editor = new project_page_module.SmartRowFormulaEditor(@firstNode)

    return

  Template.smart_row_formula_editor_opener.onDestroyed ->
    if @formula_editor?
      @formula_editor.destroy()
      @formula_editor = null

    return

  #
  # Editor template
  #
  Template.smart_row_formula_editor.onCreated ->
    @field_id = current_rendering_field_id

    return

  Template.smart_row_formula_editor.onRendered ->
    return

  getAvailableFieldsForFormula = (current_field_id) ->
    # Get all number fields and Smart Number fields that can be referenced in formulas
    project_custom_fields = project_page_module.curProj()?.getProjectCustomFields() or []
    
    available_fields = []

    # Add custom fields that are number types or calc types
    for custom_field in project_custom_fields
      # Skip the current field (no self-reference)
      if custom_field.field_id == current_field_id
        continue

      # Skip disabled fields
      if custom_field.disabled
        continue

      # Allow number fields
      if custom_field.field_type == "number"
        available_fields.push
          field_id: custom_field.field_id
          label: custom_field.label
          type: "number"

      # Allow calc fields (Smart Numbers)
      else if custom_field.field_type == "calc"
        available_fields.push
          field_id: custom_field.field_id
          label: custom_field.label
          type: "calc"

    return available_fields

  Template.smart_row_formula_editor.helpers
    currentFormula: ->
      field_id = Template.instance().field_id
      project_custom_fields = project_page_module.curProj()?.getProjectCustomFields() or []
      field_def = _.find project_custom_fields, (x) -> x.field_id == field_id

      formula = field_def?.field_options?.formula or ""

      return formula

    availableFields: ->
      field_id = Template.instance().field_id
      return getAvailableFieldsForFormula(field_id)

  Template.smart_row_formula_editor.events
    "click .add-field": (e, tpl) ->
      field_id_to_add = tpl.$(".field-to-add-selector").val()

      if not field_id_to_add
        return

      $formula_input = tpl.$(".formula-input")
      formula_input = $formula_input.get(0)

      last_pos = formula_input.selectionStart or $formula_input.val().length

      cur_text = $formula_input.val()
      text_pre_last_pos = cur_text.substr(0, last_pos)
      text_after_last_pos = cur_text.substr(last_pos)
      new_text = "#{text_pre_last_pos}{#{field_id_to_add}}#{text_after_last_pos}"

      $formula_input.val(new_text)

      # Focus the input and set cursor position after the inserted field
      new_pos = last_pos + field_id_to_add.length + 2 # +2 for the braces
      formula_input.focus()
      formula_input.setSelectionRange(new_pos, new_pos)

      return

    "click .cancel": (e, tpl) ->
      $editor = tpl.$(e.target).closest(".smart-row-formula-editor")
      $editor.data("allowDropdownClose")()
      $editor.data("close")()

      return

    "click .save": (e, tpl) ->
      current_field_id = tpl.field_id

      user_inputted_formula = tpl.$(".formula-input").val().trim()

      close = ->
        $editor = tpl.$(e.target).closest(".smart-row-formula-editor")
        $editor.data("allowDropdownClose")()
        $editor.data("close")()

        return

      # Validate the formula
      if not _.isEmpty(user_inputted_formula)
        # Extract field references and validate using the shared regex from JustdoFormulaFields
        field_component_regex = JustdoFormulaFields.formula_fields_components_matcher_regex
        referenced_fields = []
        match = null
        while (match = field_component_regex.exec(user_inputted_formula)) isnt null
          referenced_fields.push(match[1])

        if referenced_fields.length == 0
          alert(TAPi18n.__ "smart_row_formula_editor_error_no_fields")
          return

        # Validate that all referenced fields exist
        available_fields = getAvailableFieldsForFormula(current_field_id)
        available_field_ids = _.pluck(available_fields, "field_id")

        for ref_field in referenced_fields
          if ref_field not in available_field_ids
            alert(TAPi18n.__("smart_row_formula_editor_error_unknown_field", {field: ref_field}))
            return

        # Validate formula syntax with mathjs
        try
          # Replace field placeholders with symbols for validation
          symbols_indexes = "abcdefghijklmnopqrstuvwxyz"
          field_to_symbol = {}
          symbol_index = 0
          mathjs_formula = user_inputted_formula.replace field_component_regex, (match, field_id) ->
            if field_id not of field_to_symbol
              field_to_symbol[field_id] = symbols_indexes[symbol_index]
              symbol_index += 1
            return field_to_symbol[field_id]

          JustdoMathjs.parseSingleRestrictedRationalExpression(mathjs_formula)
        catch err
          alert(TAPi18n.__("smart_row_formula_editor_error_invalid_formula", {error: err.reason or err.message}))
          return

      # Save the formula to the custom field definition
      custom_fields = project_page_module.curProj()?.getProjectCustomFields()
      current_field_def = _.find custom_fields, (custom_field) -> custom_field.field_id == current_field_id

      if not current_field_def?
        alert("Field not found")
        return

      # Set the formula in field_options
      Meteor._ensure current_field_def, "field_options"
      current_field_def.field_options.formula = user_inputted_formula

      # Auto-set grid_dependencies_fields from formula placeholders
      if not _.isEmpty(user_inputted_formula)
        field_component_regex = /\{([a-zA-Z0-9:\-_]+)\}/g
        dependencies = []
        match = null
        while (match = field_component_regex.exec(user_inputted_formula)) isnt null
          if match[1] not in dependencies
            dependencies.push(match[1])

        current_field_def.grid_dependencies_fields = dependencies
      else
        delete current_field_def.grid_dependencies_fields

      # Also set grid_column_formatter_options.formula for the formatter to use
      Meteor._ensure current_field_def, "grid_column_formatter_options"
      current_field_def.grid_column_formatter_options.formula = user_inputted_formula

      project_page_module.curProj()?.setProjectCustomFields custom_fields, (err) ->
        if err?
          alert(err.reason)
          return

        close()

        return

      return
