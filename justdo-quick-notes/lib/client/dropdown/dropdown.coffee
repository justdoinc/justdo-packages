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


addNewTaskByDetectingParentFromPoint = (e) ->
  element = undefined
  elements = []
  old_visibility = []
  loop
    element = document.elementFromPoint(e.pageX, e.pageY)
    if !element or element == document.documentElement
      break
    elements.push element
    old_visibility.push element.style.visibility
    element.style.visibility = "hidden"
    # Temporarily hide the element (without changing the layout)

  k = 0

  while k < elements.length
    elements[k].style.visibility = old_visibility[k]
    k++
  elements.reverse()

  $row = $(elements).filter(".slick-row")
  $task_id = $row.find(".grid-tree-control-task-id").attr("jd-tt").split("=")[1]

  console.log $task_id

  APP.modules.project_page.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab($task_id)
  APP.modules.project_page.performOp("addSubTask")

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

      $(".quick-note").droppable
        tolerance: "pointer"
        drop: (e, ui) ->
          console.log "sort stop"

          return

      $(".slick-row").droppable
        tolerance: "pointer"
        drop: (e, ui) ->
          $task_id = $(e.target).find(".grid-tree-control-task-id").attr("jd-tt").split("=")[1]

          APP.modules.project_page.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab($task_id)
          APP.modules.project_page.performOp("addSubTask")

          return

      return

    stop: (e, ui) ->
      # Approach 1 - Add task by detecting elementFromPoint
      # addNewTaskByDetectingParentFromPoint(e)

      $(".slick-row").droppable("destroy")

      return

  return


Template.justdo_quick_notes_item.events
  "mouseenter .quick-note, mouseleave .quick-note": (e, tpl) ->
    $(e.currentTarget).removeClass "mouse-down"
    $(e.currentTarget).draggable disabled: false

    return

  "mousedown .quick-note": (e, tpl) ->
    $(e.currentTarget).addClass "mouse-down"

    return

  "mouseup .quick-note": (e, tpl) ->
    $(e.currentTarget).removeClass "mouse-down"
    $(e.currentTarget).draggable disabled: true
    $(e.currentTarget).find(".quick-note-title").focus()

    return


















# ---------
