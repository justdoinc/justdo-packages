ColorsPickerDropdown = JustdoHelpers.generateNewTemplateDropdown "justdo-color-picker-dropdown", "justdo_color_picker_dropdown_content",
  custom_dropdown_class: "dropdown-menu justdo-color-picker-dropdown-container animate slideIn shadow-lg border-0"
  custom_bound_element_options:
    close_button_html: null

    keep_open_while_bootbox_active: false

    close_on_esc: true

    container: ".modal-content"

    close_on_context_menu_outside: false
    close_on_click_outside: false
    close_on_mousedown_outside: true
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

      return

    closedHandler: ->
      $(".controller-template").off "scroll", @controller_template_scroll_handler
      $(".project-configuration-dialog").off "scroll", @project_configuration_dialog_scroll_handler

      return

  updateDropdownPosition: ($connected_element) ->
    @$dropdown
      .position
        of: $connected_element
        my: "middle top"
        at: "left bottom"
        collision: "fit fit"
        using: (new_position, details) =>
          target = details.target
          element = details.element

          element.element.css
            top: new_position.top + 2
            left: new_position.left + 10

Template.justdo_color_picker_dropdown.onCreated ->
  @color_picker_dropdown = null

  return

Template.justdo_color_picker_dropdown.onRendered ->
  @color_picker_dropdown = new ColorsPickerDropdown(@firstNode, {color_picker_controller: @data.color_picker_controller, color_picker_dropdown: @color_picker_dropdown})

  return

Template.justdo_color_picker_dropdown.onDestroyed ->
  if @color_picker_dropdown?
    @color_picker_dropdown.destroy()
    @color_picker_dropdown = null

  return

Template.justdo_color_picker_dropdown_content.onCreated ->
  @color_picker_controller = @data.color_picker_controller

  return

Template.justdo_color_picker_dropdown_content.onRendered ->
  @color_picker_dropdown = $(this.view._domrange.parentElement).closest(".justdo-color-picker-dropdown").data()

  return

Template.justdo_color_picker_dropdown.helpers
  showTransparentBackground: (color) ->
    return color == "00000000"

Template.justdo_color_picker_dropdown_content.helpers
  isSelectedColor: ->
    tpl = Template.instance()

    current_color = String(@)

    return current_color == tpl.color_picker_controller.getSelectedColor()

  colorArrays: ->
    color_arrays = []
    available_colors = @.color_picker_controller.options.available_colors

    color_array = []

    # chunk - is a number of colors in one vertical palette
    chunk = 6
    i = 0
    while i < available_colors.length
      color_array = available_colors.slice(i, i + chunk)
      color_arrays.push color_array
      i += chunk

    return color_arrays

  showTransparentBackground: (color) ->
    return color == "00000000"

  contrastClasses: ->
    current_color = String(@)

    contrast_classes = ""

    if current_color.toLowerCase() == "ffffff" or current_color.toLowerCase() == "00000000"
      contrast_classes += "justdo-color-picker-contrast-required"

    return contrast_classes

Template.justdo_color_picker_dropdown_content.events
  "click .justdo-color-picker-color-option": (e, tpl) ->
    selected_color = String(@)

    tpl.data.color_picker_controller.setSelectedColor(selected_color)

    tpl.color_picker_dropdown.close()

    return
