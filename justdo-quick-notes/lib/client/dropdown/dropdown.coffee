share.QuickNotesDropdown = JustdoHelpers.generateNewTemplateDropdown "quick-notes-dropdown", "justdo_quick_notes_dropdown",
  custom_bound_element_options:
    close_button_html: null

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
          element.element.addClass "animate slideIn shadow-lg bg-white"
          element.element.css
            top: new_position.top - 7
            left: new_position.left + 20

      $(".dropdown-menu.show").removeClass("show") # Hide active dropdown

    return


# !!!!! Bug with MEMBERS DROPDOWN !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Template.justdo_quick_notes_dropdown.onCreated ->
  @showCompleted = new ReactiveVar false

  @quickNotes = [
    { title: "Seoul", completed: true },
    { title: "Berlin", completed: true },
    { title: "Moscow", completed: true },
    { title: "Hong Kong", completed: false },
    { title: "Paris", completed: false },
    { title: "Perth", completed: false },
    { title: "Kuala Lumpur", completed: true },
    { title: "New York", completed: false },
    { title: "London", completed: false },
    { title: "Rome", completed: false },
    { title: "Barselona", completed: true },
    { title: "Amsterdam", completed: false },
    { title: "Los Angeles", completed: false },
    { title: "Nice", completed: false },
    { title: "Marsel", completed: false },
    { title: "Kuala Lumpur", completed: true },
    { title: "New York", completed: false },
    { title: "London", completed: false },
    { title: "Rome", completed: false },
    { title: "Barselona", completed: true },
    { title: "Amsterdam", completed: false },
    { title: "Los Angeles", completed: false },
    { title: "Nice", completed: true },
    { title: "Marsel", completed: false }
  ]

  return

Template.justdo_quick_notes_dropdown.helpers
  quckNotes: ->
    return Template.instance().quickNotes

  showCompleted: ->
    return Template.instance().showCompleted.get()

Template.justdo_quick_notes_dropdown.events
  "click .quick-notes-completed-wrapper .quick-notes-list-title": (e, tpl) ->
    tpl.showCompleted.set !tpl.showCompleted.get()

    return


Template.justdo_quick_notes_item.onRendered ->
  $(".quick-note").draggable
    cursor: "none"
    helper: "clone"
    # zIndex: 100
    refreshPositions: true
    start: (e, ui) ->
      # To avoid size changes while dragging set the width of ui.helper equal to the width of an active task
      #$(ui.helper).width($(event.target).closest(".calendar_task_cell").width())
      # Append an element to the table to avoid destruction when updating the table
      #$(ui.helper).appendTo(".calendar_view_main_table_wrapper")
      #createDroppableWrapper()
      return
    stop: (e, ui) ->
      #destroyDroppableWrapper()
      return

  return


Template.justdo_quick_notes_item.events
  "mousedown .quick-note": (e, tpl) ->
    $(e.currentTarget).addClass "mouse-down"

    return

  "mouseup .quick-note, mouseleave .quick-note": (e, tpl) ->
    $(e.currentTarget).removeClass "mouse-down"

    return


















# ---------
