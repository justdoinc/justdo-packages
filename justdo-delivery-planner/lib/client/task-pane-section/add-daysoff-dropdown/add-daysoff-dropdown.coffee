APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  AddDaysoffDropdown = JustdoHelpers.generateNewTemplateDropdown "justdo-delivery-planner-task-pane-add-daysoff-dropdown", "delivery_planner_task_pane_add_daysoff_dropdown",
    custom_dropdown_class: "dropdown-menu justdo-delivery-planner-task-pane-add-daysoff-dropdown-container"
    custom_bound_element_options:
      close_button_html: null

      keep_open_while_bootbox_active: false

      close_on_esc: false

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

        # We want the user to have to use the save/cancel button, and prevent accidental close of
        # the editor.
        @$dropdown.data("preventDropdownClose")()

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


  Template.delivery_planner_task_pane_add_daysoff_btn.onCreated ->
    @add_daysoff_dropdown = null

    return

  Template.delivery_planner_task_pane_add_daysoff_btn.onRendered ->
    @add_daysoff_dropdown = new AddDaysoffDropdown(@firstNode, @data)

    return

  Template.delivery_planner_task_pane_add_daysoff_btn.onDestroyed ->
    @add_daysoff_dropdown.destroy()

    return


  Template.delivery_planner_task_pane_add_daysoff_dropdown_date_field_editor.onRendered ->
    field_id = "start_date"

    gc = APP.modules.project_page.gridControl()

    field_editor = gc.generateFieldEditor(field_id, null) # null means we aren't editing any document in practice, just a fake editor, we are using start_date just for its configuration

    #
    # Editor specific modifications
    #
    $firstNode = $(@firstNode)
    $firstNode.data("editor_field_id", field_id)    
    $firstNode.data("editor", field_editor)
    $(@firstNode).html(field_editor.$dom_node)

    $firstNode.find(".editor-unicode-date")
      .keydown (e) ->
        if e.which == 13
          field_editor.save()

          $(e.target).blur()

          return

        if e.which == 27
          field_editor.cancel()

          $(e.target).blur()

          return

      .blur (e) ->
        if not $("#ui-datepicker-div").is(":visible")
          field_editor.save()

        return

      .data("field_editor", field_editor)
      .data().datepicker.settings.onSelect = ->
        $(@).change()

        field_editor.save()

        return

    $(window).trigger("resize.autosize")

    return

  Template.delivery_planner_task_pane_add_daysoff_dropdown.onCreated ->
    @date_editors_errors_deps = new Tracker.Dependency()

    @date_editors_errors = null
    @initDateEditorsErrors = ->
      @date_editors_errors = {start: [], end: [], general: []}

      @date_editors_errors_deps.changed()

      return
    @initDateEditorsErrors()

    @getDateEditorsInfo = ->
      $start_editor = $(".daysoff-range-start-input-group")
                        .find(".editor-unicode-date")

      $end_editor = $(".daysoff-range-end-input-group")
                        .find(".editor-unicode-date")

      editors =
        start:
          $el: $start_editor
          datepicker: $start_editor.data("datepicker")
          field_editor: $start_editor.data("field_editor")

        end:
          $el: $end_editor
          datepicker: $end_editor.data("datepicker")
          field_editor: $end_editor.data("field_editor")

      editors.start.is_valid = editors.start.field_editor.editor.validate().valid
      editors.end.is_valid = editors.end.field_editor.editor.validate().valid

      editors.start.is_empty = _.isEmpty editors.start.$el.val().trim()
      editors.end.is_empty = _.isEmpty editors.end.$el.val().trim()

      editors.start.val = editors.start.field_editor.editor.getValue()
      editors.end.val = editors.end.field_editor.editor.getValue()

      return editors

    @validateDateEditorsAndSetAutoValues = (edited_field) ->
      @initDateEditorsErrors()

      editors = @getDateEditorsInfo()

      if not editors.start.is_valid
        @date_editors_errors.start.push "Invalid start date"

      if not editors.end.is_valid
        @date_editors_errors.end.push "Invalid end date"

      if not editors.end.is_empty and editors.start.is_valid and editors.end.is_valid and editors.end.val < editors.start.val
        @date_editors_errors.end.push "End date is before start date"

      @date_editors_errors_deps.changed()

      # Auto set end to start date if end date isn't set and vice versa
      if edited_field == "start" and editors.start.is_valid and editors.end.is_empty
        editors.end.$el.val(editors.start.$el.val())

        editors.end.$el.trigger("change")

      if edited_field == "end" and editors.end.is_valid and editors.start.is_empty
        editors.start.$el.val(editors.end.$el.val())

        editors.start.$el.trigger("change")

      return

    @getDateEditorsErrors = ->
      @date_editors_errors_deps.depend()

      return @date_editors_errors

    @getFlattenDateEditorsErrors = ->
      return _.union(_.values(_.filter(@getDateEditorsErrors(), (e) -> not _.isEmpty(e))))

    @dateInputChanged = (input) ->
      @validateDateEditorsAndSetAutoValues(input)

      return

    return


  Template.delivery_planner_task_pane_add_daysoff_dropdown.events
    "click .cancel": (e) ->
      Meteor.defer ->
        $(e.target).closest(".justdo-delivery-planner-task-pane-add-daysoff-dropdown").data("allowDropdownClose")()
        $(e.target).closest(".justdo-delivery-planner-task-pane-add-daysoff-dropdown").data("close")()

      return

    "click .add": (e) ->
      tpl = Template.instance()

      if not _.isEmpty tpl.getFlattenDateEditorsErrors()
        return

      editors_info = tpl.getDateEditorsInfo()
      start_val = editors_info.start.val
      end_val = editors_info.end.val

      if not start_val? or not end_val?
        return

      daysoff_ranges = tpl.data.member_controller.getExtendedDaysoffRanges()
      daysoff_ranges.push([start_val, end_val])
      daysoff_ranges = _.filter daysoff_ranges, (range) -> not _.isEmpty(range)

      tpl.data.member_controller.setExtendedDaysoffRanges(daysoff_ranges)

      Meteor.defer ->
        $(e.target).closest(".justdo-delivery-planner-task-pane-add-daysoff-dropdown").data("allowDropdownClose")()
        $(e.target).closest(".justdo-delivery-planner-task-pane-add-daysoff-dropdown").data("close")()

      return

    "click .add-daysoff-controllers-container, click .dropdown-add-daysoff-controls-container": (e) ->
      if not $(e.target).hasClass("udf-action-btn")
        $(".ui-datepicker").remove()

      return

    "change .editor-unicode-date": (e, tpl) ->
      $input = $(e.target)
      val = $input.val()
      if $input.closest(".daysoff-range-start-input-group").length > 0
        tpl.dateInputChanged("start")
      else
        tpl.dateInputChanged("end")

      return

  Template.delivery_planner_task_pane_add_daysoff_dropdown.helpers
    startHasError: ->
      tpl = Template.instance()

      tpl.getDateEditorsErrors()

      return not _.isEmpty tpl.getDateEditorsErrors().start

    endHasError: ->
      tpl = Template.instance()

      tpl.getDateEditorsErrors()

      return not _.isEmpty tpl.getDateEditorsErrors().end

    getDateInputsErrors: ->
      tpl = Template.instance()

      return tpl.getFlattenDateEditorsErrors()

