APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  module.CustomFieldFormulaFieldEditor = JustdoHelpers.generateNewTemplateDropdown "custom-field-formula-field-editor", "custom_field_conf_formula_field_editor",
    custom_dropdown_class: "dropdown-menu"
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
  # Select options editor opener
  #
  Template.custom_field_conf_formula_field_editor_opener.onCreated ->
    @options_editor = null

    return

  Template.custom_field_conf_formula_field_editor_opener.onRendered ->
    @options_editor = new module.CustomFieldFormulaFieldEditor(@firstNode, {field_id: @data.field_id})

    return

  Template.custom_field_conf_formula_field_editor_opener.onDestroyed ->
    if @options_editor?
      @options_editor.destroy()
      @options_editor = null

    return

  #
  # Select options editor
  #
  Template.custom_field_conf_formula_field_editor.onCreated ->
    return

  Template.custom_field_conf_formula_field_editor.onRendered ->
    return

  Template.custom_field_conf_formula_field_editor.helpers
    availableFields: ->
      return APP.justdo_formula_fields.getFieldsAvailableForFormulasInCurrentLoadedProject(@field_id, false)

    getHumanReadableFormula: ->
      formula = APP.collections.Formulas.findOne({custom_field_id: @field_id})?.formula or ""

      if not _.isEmpty(formula)
        return APP.justdo_formula_fields.getHumanReadableFormulaForCurrentLoadedProject(formula, @field_id)

      return ""

  Template.custom_field_conf_formula_field_editor.events
    "click .add-field": (e, tpl) ->
      label_to_add = tpl.$(".field-to-add-selector").val()

      $formula_input = tpl.$(".formula-input")
      formula_input = $formula_input.get(0)

      last_pos = formula_input.selectionStart or 0

      cur_text = $formula_input.val()
      text_pre_last_pos = cur_text.substr(0, last_pos)
      text_after_last_pos = cur_text.substr(last_pos)
      new_text = "#{text_pre_last_pos}{#{label_to_add}}#{text_after_last_pos}"

      field_to_add = $formula_input.val(new_text)

      return

    "click .cancel": (e, tpl) ->
      $options_editor = tpl.$(e.target).closest(".custom-field-formula-field-editor")
      $options_editor.data("allowDropdownClose")()
      $options_editor.data("close")()

      return

    "click .open-formula-editor-help": (e, tpl) ->
      APP.justdo_formula_fields.showFormulaEditingRulesDialog()

      return

    "click .save": (e, tpl) ->
      current_field_id = @field_id

      # Edit field_options
      user_inputted_formula = tpl.$(".formula-input").val().trim()

      close = ->
        $options_editor = tpl.$(e.target).closest(".custom-field-formula-field-editor")
        $options_editor.data("allowDropdownClose")()
        $options_editor.data("close")()

        return

      saveFormulaAndClose = (formula) ->
        APP.justdo_formula_fields.setCustomFieldFormula module.curProj().id, current_field_id, formula, (err) ->
          if err?
            alert(err.reason)

            return

          close()

          return

      if _.isEmpty(user_inputted_formula)
        saveFormulaAndClose(null)
      else
        APP.justdo_formula_fields.getFormulaFromHumanReadableFormulaForCurrentLoadedProject user_inputted_formula, current_field_id, (err, formula) ->
          if err?
            alert(err.reason)

            return

          saveFormulaAndClose(formula)

          return

      return