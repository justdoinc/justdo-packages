ProjectBaseWorkdaysDropdown = JustdoHelpers.generateNewTemplateDropdown "justdo-delivery-planner-task-pane-workdays-editor-dropdown", "delivery_planner_task_pane_workdays_editor_dropdown",
  custom_dropdown_class: "dropdown-menu justdo-delivery-planner-task-pane-workdays-editor-dropdown-container"
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

      workdays = [0, 0, 0, 0, 0, 0, 0]
      $(".project-base-workday-checkbox").each ->
        $btn = $(@)

        if $btn.is(":checked")
          workdays[parseInt($btn.val())] = 1

        return

      this.template_data.workdays_editor.setWorkdays(workdays)

      return

  updateDropdownPosition: ($connected_element) ->
    @$dropdown
      .position
        of: $connected_element
        my: "right top"
        at: "right bottom"
        collision: "fit fit"
        using: (new_position, details) =>
          target = details.target
          element = details.element

          element.element.css
            top: new_position.top + 2
            left: new_position.left


Template.delivery_planner_task_pane_workdays_editor_btn.onCreated ->
  @base_workdays_dropdown = null

  return

Template.delivery_planner_task_pane_workdays_editor_btn.onRendered ->
  @base_workdays_dropdown = new ProjectBaseWorkdaysDropdown(@firstNode, @data)

  return

Template.delivery_planner_task_pane_workdays_editor_btn.onDestroyed ->
  @base_workdays_dropdown.destroy()

  return

Template.delivery_planner_task_pane_workdays_editor_dropdown.onCreated ->
  @existing_workdays = @data.workdays_editor.getCurrentWorkdays()

  return

Template.delivery_planner_task_pane_workdays_editor_dropdown.helpers
  isWorkdaySelected: (id) ->
    tpl = Template.instance()

    return tpl.existing_workdays[id] == 1
