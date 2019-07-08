default_option_color = "ffffff"
available_colors = ["ffffff", "d50001", "e57c73", "f4521e", "f6bf25", "33b679", "0a8043", "019be5", "3f51b5" ,"7986cb", "8d24aa", "616161", "4285f4", "000000"]

generatePickerDropdown = (selected_color) ->
  return new JustdoColorPickerDropdownController
    label: "Pick a background color"
    opener_custom_class: "custom-fields-justdo-color-picker-opener"
    default_color: selected_color
    available_colors: available_colors

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  module.CustomFieldFormulaFieldEditor = JustdoHelpers.generateNewTemplateDropdown "custom-field-formula-field-editor", "custom_field_conf_formula_field_editor",
    custom_dropdown_class: "dropdown-menu animate slideIn shadow-lg border-0 p-3"
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

  #
  # Select options editor
  #
  appendOptionToEditor = ($options_list, id, label, range, bg_color) ->
    [begin, end] = range

    begin_txt = if begin? then begin else ""
    end_txt = if end? then end else ""

    $option_dom = $("""
      <div class="custom-field-option" option-id="#{id}">
        <div class="option-handle">
          <i class="fa fa-bars" aria-hidden="true"></i>
        </div>
        <div class="option-label"><input type="text" placeholder="Filter label" value="#{label}" /></div>
        <div class="option-begin"><input type="text" placeholder="Begin" value="#{begin_txt}" /></div>
        <div class="option-end"><input type="text" placeholder="End" value="#{end_txt}" /></div>
        <div class="bg-color-selector">#{bg_color}</div>
        <div class="remove-option" title="Remove option"><i class="fa fa-trash-o" aria-hidden="true"></i></div>
      </div>
    """)

    $options_list.append $option_dom

    color_picker_controller =
      generatePickerDropdown(bg_color)

    $(".bg-color-selector", $option_dom).data("color_picker_controller", color_picker_controller)

    color_picker_dropdown_node =
      APP.helpers.renderTemplateInNewNode("justdo_color_picker_dropdown", {color_picker_controller: color_picker_controller})

    $(".bg-color-selector", $option_dom).html color_picker_dropdown_node.node

    return

  Template.custom_field_conf_formula_field_editor.onCreated ->
    @field_id = @data.field_id

    @show_add_button = new ReactiveVar(false)

    @new_option_color_picker_dropdown_controller =
      generatePickerDropdown(default_option_color)

    @updateAddButtonState = =>
      if $(".new-option-label").val() == ""
        @show_add_button.set(false)
      else
        @show_add_button.set(true)

      return

    return

  Template.custom_field_conf_formula_field_editor.onRendered ->
    project_custom_fields = module.curProj()?.getProjectCustomFields()
    field_def = _.find project_custom_fields, (x) => x.field_id == @field_id

    grid_ranges = field_def.grid_ranges

    $options_list = @view.templateInstance().$(".custom-field-options")

    if grid_ranges?
      for range_def in grid_ranges
        {id, label, range, bg_color} = range_def

        if not bg_color?
          bg_color = default_option_color

        appendOptionToEditor($options_list, id, label, range, bg_color)

    $options_list.sortable
      handle: ".option-handle"
      axis: "y"

    return

  addOption = (tpl) ->
    $label_input = tpl.$(".new-option-label")
    $begin_input = tpl.$(".new-option-begin")
    $end_input = tpl.$(".new-option-end")

    if _.isEmpty (option_label = $label_input.val())
      # No label entered
      return

    begin_value = $begin_input.val().trim()
    if begin_value is ""
      begin_value = null
    else
      begin_value = parseFloat(begin_value)

    end_value = $end_input.val().trim()
    if end_value is ""
      end_value = null
    else
      end_value = parseFloat(end_value)

    range = [begin_value, end_value]

    if _.isNaN(range[0]) or _.isNaN(range[1])
      alert("Invalid begin/end values given to filter.")

      return

    if range[0]? and range[1]? and range[0] > range[1]
      alert("Filter's Begin value can't be bigger than End value.")

      return

    if not range[0]? and not range[1]?
      alert("Filter must have either Begin or End value.")

      return

    option_id = Random.id()

    option_background_color =
      tpl.new_option_color_picker_dropdown_controller.getSelectedColor()

    $custom_field_options = tpl.$(".custom-field-options")
    appendOptionToEditor($custom_field_options, option_id, option_label, range, option_background_color)

    $custom_field_options.scrollTop($custom_field_options[0].scrollHeight);

    $label_input.val("").keyup() # keyup to update add button state
    $begin_input.val("")
    $end_input.val("")

    tpl.new_option_color_picker_dropdown_controller.setSelectedColor(default_option_color)

    return

  Template.custom_field_conf_formula_field_editor.helpers
    showAddButton: ->
      tpl = Template.instance()

      return tpl.show_add_button.get()

    colorPickerDropdownController: ->
      tpl = Template.instance()

      return tpl.new_option_color_picker_dropdown_controller

    availableFields: ->
      return APP.justdo_formula_fields.getFieldsAvailableForFormulasInCurrentLoadedProject(@field_id, false)

    getHumanReadableFormula: ->
      formula = APP.collections.Formulas.findOne({custom_field_id: @field_id})?.formula or ""

      if not _.isEmpty(formula)
        return APP.justdo_formula_fields.getHumanReadableFormulaForCurrentLoadedProject(formula, @field_id)

      return ""

  Template.custom_field_conf_formula_field_editor.events
    "click .add-option": (e, tpl) ->
      addOption(tpl)

      return

    "keyup .new-option-label, keyup .new-option-begin, keyup .new-option-end": (e, tpl) ->
      tpl.updateAddButtonState()

      if e.keyCode == 13
        addOption(tpl)

      return

    "click .remove-option": (e, tpl) ->
      if confirm("Are you sure you want to remove this filter?")
        $(e.target).closest(".custom-field-option").remove()

      return

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

      user_inputted_formula = tpl.$(".formula-input").val().trim()

      close = ->
        $options_editor = tpl.$(e.target).closest(".custom-field-formula-field-editor")
        $options_editor.data("allowDropdownClose")()
        $options_editor.data("close")()

        return

      saveFieldOptionsAndClose = ->
        grid_ranges = []

        validation_failed = false
        $(e.target).closest(".custom-field-formula-field-editor-content").find(".custom-field-option").each ->
          id = $(this).attr("option-id")
          label = $(this).find(".option-label input").val().trim()
          begin = $(this).find(".option-begin input").val().trim()
          end = $(this).find(".option-end input").val().trim()
          bg_color = $(this).find(".bg-color-selector").data("color_picker_controller").getSelectedColor()

          if _.isEmpty label
            alert("Error: Every filter must have a label set.")

            validation_failed = true

            return

          if begin is ""
            begin = null
          else
            begin = parseFloat(begin)

            if _.isNaN begin
              alert("Error: Filter '#{label}' has an invalid Begin value.")

              validation_failed = true

              return

          if end is ""
            end = null
          else
            end = parseFloat(end)

            if _.isNaN end
              alert("Error: Filter '#{label}' has an invalid End value.")

              validation_failed = true

              return

          if not begin? and not end?
            alert("Error: Filter '#{label}' you must define either Begin or End value.")

            validation_failed = true

            return

          if begin? and end? and begin > end
            alert("Error: Filter '#{label}' Begin value is bigger than End value.")

            validation_failed = true

            return

          range = [begin, end]

          grid_ranges.push {id: id, label: label, range: range, bg_color: bg_color}

          return

        if validation_failed
          return

        custom_fields = module.curProj()?.getProjectCustomFields()
        current_field_def = _.find custom_fields, (custom_field) -> custom_field.field_id == current_field_id

        if not _.isEmpty(grid_ranges)
          current_field_def.grid_ranges = grid_ranges
          current_field_def.filter_type = "numeric-filter"
        else
          delete current_field_def.grid_ranges
          delete current_field_def.filter_type

        module.curProj()?.setProjectCustomFields custom_fields, (err) ->
          if err?
            alert(err.reason)

            return

          close()

          return

        return

      saveFormulaAndClose = (formula) ->
        APP.justdo_formula_fields.setCustomFieldFormula module.curProj().id, current_field_id, formula, (err) ->
          if err?
            alert(err.reason)

            return

          saveFieldOptionsAndClose()

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
