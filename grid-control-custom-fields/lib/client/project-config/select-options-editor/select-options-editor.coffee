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

  module.CustomFieldSelectOptionsEditor = JustdoHelpers.generateNewTemplateDropdown "custom-field-select-options-editor", "custom_field_conf_select_options_editor",
    custom_dropdown_class: "dropdown-menu shadow-lg border-0 py-3"
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

        # $(".bound-element.open").data("allowDropdownClose")()
        # $(".bound-element.open").data("close")()

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
  Template.custom_field_conf_select_options_editor_opener.onCreated ->
    @options_editor = null

    return

  # XXX Not the perfect way to pass data, but quick workaround to the level of complexity
  # the bound element mechanisems reached, Daniel C.
  current_rendering_field_id = null
  Template.custom_field_conf_select_options_editor_opener.onRendered ->
    $(@firstNode).click =>
      current_rendering_field_id = @data.field_id

    @options_editor = new module.CustomFieldSelectOptionsEditor(@firstNode)

    return

  Template.custom_field_conf_select_options_editor_opener.onDestroyed ->
    if @options_editor?
      @options_editor.destroy()
      @options_editor = null

    return

  #
  # Select options editor
  #
  appendOptionToEditor = ($options_list, option_id, option_label, option_background_color) ->
    $option_dom = $("""
      <div class="custom-field-option d-flex align-items-center" option-id="#{JustdoHelpers.xssGuard option_id}">
        <svg class="jd-icon-custom-field text-muted option-handle"><use xlink:href="/layout/icons-feather-sprite.svg#menu"/></svg>
        <input class="option-label form-control form-control-sm border-0 bg-transparent text-body my-1 ml-1" type="text" placeholder="Label name" value="#{JustdoHelpers.xssGuard option_label}">
        <div class="bg-color-selector">#{JustdoHelpers.xssGuard option_background_color}</div>
        <svg class="jd-icon-custom-field text-primary remove-option"><use xlink:href="/layout/icons-feather-sprite.svg#x"/></svg>
      </div>
    """)

    $options_list.append $option_dom

    color_picker_controller =
      generatePickerDropdown(option_background_color)

    $(".bg-color-selector", $option_dom).data("color_picker_controller", color_picker_controller)

    color_picker_dropdown_node =
      APP.helpers.renderTemplateInNewNode("justdo_color_picker_dropdown", {color_picker_controller: color_picker_controller})

    $(".bg-color-selector", $option_dom).html color_picker_dropdown_node.node

    return

  Template.custom_field_conf_select_options_editor.onCreated ->
    @show_add_button = new ReactiveVar false
    @show_sort_button = new ReactiveVar false

    @new_option_color_picker_dropdown_controller =
      generatePickerDropdown(default_option_color)

    @updateAddButtonState = =>
      if $(".new-option-label").val() == ""
        @show_add_button.set(false)
      else
        @show_add_button.set(true)

      return

    return

  Template.custom_field_conf_select_options_editor.onRendered ->
    @field_id = current_rendering_field_id

    project_custom_fields = module.curProj()?.getProjectCustomFields()
    field_def = _.find project_custom_fields, (x) => x.field_id == @field_id

    field_options = field_def.field_options

    $options_list = @view.templateInstance().$(".custom-field-options")

    if field_options?
      if field_options.select_options.length > 5
        @show_sort_button.set true

      for option_def in field_options.select_options
        {option_id, label, bg_color} = option_def

        if not bg_color?
          bg_color = default_option_color

        appendOptionToEditor($options_list, option_id, label, bg_color)

    firstSort = true # firstSort need to avoid Jquery-UI issue when the sortable element jumps ( on the first sort )
    $options_list.sortable
      handle: ".option-handle"
      axis: "y"
      start: (event, ui) ->
        if firstSort
          $options_list.sortable 'refreshPositions'
          firstSort = false
        return

    return

  addOption = (tpl) ->
    $label_input = tpl.$(".new-option-label")

    if _.isEmpty (option_label = $label_input.val())
      # No label entered
      return

    option_id = Random.id()

    option_background_color = default_option_color

    $custom_field_options = tpl.$(".custom-field-options")
    appendOptionToEditor($custom_field_options, option_id, option_label, option_background_color)

    $custom_field_options.scrollTop($custom_field_options[0].scrollHeight);

    $label_input.val("").keyup() # keyup to update add button state

    tpl.new_option_color_picker_dropdown_controller.setSelectedColor(default_option_color)

    return

  Template.custom_field_conf_select_options_editor.helpers
    showAddButton: ->
      tpl = Template.instance()

      return tpl.show_add_button.get()

    colorPickerDropdownController: ->
      tpl = Template.instance()

      return tpl.new_option_color_picker_dropdown_controller

    showSortButton: ->
      tpl = Template.instance()

      return tpl.show_sort_button.get()

  Template.custom_field_conf_select_options_editor.events
    "click .add-option": (e, tpl) ->
      addOption(tpl)

      if $(".custom-field-option").length > GridControlCustomFieldsManager.min_items_to_show_sort_by_name_in_options_editor
        tpl.show_sort_button.set true

      return

    "keyup .new-option-label": (e, tpl) ->
      tpl.updateAddButtonState()

      if e.keyCode == 13
        addOption(tpl)

        if $(".custom-field-option").length > GridControlCustomFieldsManager.min_items_to_show_sort_by_name_in_options_editor
          tpl.show_sort_button.set true

      return

    "click .remove-option": (e, tpl) ->
      if confirm("Are you sure you want to remove this option?")
        $(e.target).closest(".custom-field-option").remove()

        if $(".custom-field-option").length <= GridControlCustomFieldsManager.min_items_to_show_sort_by_name_in_options_editor
          tpl.show_sort_button.set false

      return

    "click .cancel": (e, tpl) ->
      $options_editor = $(e.target).closest(".custom-field-select-options-editor")
      $options_editor.data("allowDropdownClose")()
      $options_editor.data("close")()

      return

    "click .save": (e, tpl) ->
      select_options = []

      $(e.target).closest(".custom-field-select-options-editor-content").find(".custom-field-option").each ->
        option_id = $(this).attr("option-id")
        option_label = $(this).find(".option-label").val()
        bg_color = $(this).find(".bg-color-selector").data("color_picker_controller").getSelectedColor()

        select_options.push {option_id, label: option_label, bg_color: bg_color}

        return

      custom_fields = module.curProj()?.getProjectCustomFields()
      current_field_def = _.find custom_fields, (custom_field) -> custom_field.field_id == Template.instance().field_id

      Meteor._ensure current_field_def, "field_options"
      current_field_def.field_options.select_options = select_options
      module.curProj()?.setProjectCustomFields(custom_fields, -> return)

      $options_editor = $(e.target).closest(".custom-field-select-options-editor")
      $options_editor.data("allowDropdownClose")()
      $options_editor.data("close")()

      return

    "click .sort-alphabetically": (e, tpl) ->
      options = []
      options_content = $(e.target).closest(".custom-field-select-options-editor-content")

      for option in options_content.find(".custom-field-option")
        options.push $(option)

      options.sort (a, b) ->
        return $(a).find(".option-label").val().toUpperCase().localeCompare $(b).find(".option-label").val().toUpperCase()

      for option in options
        options_content.find(".custom-field-options").append option

      return
