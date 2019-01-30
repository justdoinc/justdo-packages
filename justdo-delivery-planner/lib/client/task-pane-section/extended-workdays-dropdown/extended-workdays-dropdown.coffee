APP.executeAfterAppLibCode ->
  devPlanner = -> APP.justdo_delivery_planner

  dataTypeDef = -> devPlanner().getTimeMinutesDataTypeDef()

  ExtendedWorkdaysDropdown = JustdoHelpers.generateNewTemplateDropdown "justdo-delivery-planner-task-pane-extended-workdays-editor-dropdown", "delivery_planner_task_pane_extended_workdays_editor_dropdown",
    custom_dropdown_class: "dropdown-menu justdo-delivery-planner-task-pane-extended-workdays-editor-dropdown-container"
    custom_bound_element_options:
      close_button_html: null

      keep_open_while_bootbox_active: false

      close_on_esc: true

      container: "body"

      close_on_context_menu_outside: false
      close_on_click_outside: false
      close_on_mousedown_outside: true
      close_on_bound_elements_show: false

      close_on_bootstrap_dropdown_show: false

      openedHandler: ->
        @controller_template_scroll_handler = =>
          @$dropdown.data("updatePosition")()

          return

        $(".task-pane-content").on "scroll", @controller_template_scroll_handler

        return

      beforeClosedHandler: ->
        $(".task-pane-content").off "scroll", @controller_template_scroll_handler

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
              left: new_position.left - 13


  Template.delivery_planner_task_pane_extended_workdays_editor_btn.onCreated ->
    @base_workdays_dropdown = null

    return

  Template.delivery_planner_task_pane_extended_workdays_editor_btn.onRendered ->
    @base_workdays_dropdown = new ExtendedWorkdaysDropdown(@firstNode, @data)

    return

  Template.delivery_planner_task_pane_extended_workdays_editor_btn.onDestroyed ->
    @base_workdays_dropdown.destroy()

    return

  Template.delivery_planner_task_pane_extended_workdays_editor_dropdown.helpers
    getWorkdayValue: (id) ->
      return dataTypeDef().formatter(@member_controller.getExtendedDailyAvailability()[id])

    placeholder: ->
      return dataTypeDef().empty_val_placeholder

  Template.delivery_planner_task_pane_extended_workdays_editor_dropdown.events
    "change .extended-daily-availability,focusout .extended-daily-availability": (e, tpl) ->
      user_input_val = $(e.target).val().trim()
      day_index = parseInt($(e.target).attr("day-index"), 10)

      if _.isEmpty(user_input_val)
        user_input_val = "0"

      new_val = dataTypeDef().userInputToValTranslator(user_input_val)
      if _.isString new_val
        # If remains string, parsing failed, use 0
        new_val = 0

      if new_val < 0
        new_val = 0

      new_formatted_val = dataTypeDef().formatter(new_val)

      # We need the new value to the dom, for case the user changed the value to a value
      # that translates to the same underlying value (think a change from 3:00 to 3), in
      # such case blaze won't update the dom
      $(e.target).val(new_formatted_val)

      new_extended_daily_availability = @member_controller.getExtendedDailyAvailability()
      new_extended_daily_availability[day_index] = new_val

      @member_controller.setExtendedDailyAvailability(new_extended_daily_availability)

      return

