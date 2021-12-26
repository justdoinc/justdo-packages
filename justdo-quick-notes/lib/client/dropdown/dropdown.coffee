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

      $(".dropdown-menu.show").removeClass("show")

    return

Template.justdo_quick_notes_dropdown.onCreated ->
  @showCompleted = new ReactiveVar false
  @completedQuickNotesLimit = new ReactiveVar 20

  active_quick_notes_sub = APP.justdo_quick_notes.subscribeActiveQuickNotes()
  completed_quick_notes_sub = APP.justdo_quick_notes.subscribeCompletedQuickNotes({limit: @completedQuickNotesLimit.get()})

  return

Template.justdo_quick_notes_dropdown.onRendered ->
  $(".quick-note-add").focus()

  $(".quick-notes-list.completed").on "scroll", ->
    if $(this).scrollTop() + $(this).innerHeight() >= $(this)[0].scrollHeight
      console.log "end reached"

    return

  return

Template.justdo_quick_notes_dropdown.helpers
  quickNotes: ->
    return APP.collections.QuickNotes.find({}, {sort: {order: -1}}).fetch()

  showCompleted: ->
    return Template.instance().showCompleted.get()

  noActiveQuickNotes: ->
    return true

  noCompletedQuickNotes: ->
    return true

Template.justdo_quick_notes_dropdown.events
  "click .quick-notes-completed-wrapper .quick-notes-list-title": (e, tpl) ->
    tpl.showCompleted.set !tpl.showCompleted.get()

    return

  "keydown .quick-note-add": (e, tpl) ->
    if e.key == "Enter"
      e.preventDefault()

      $quick_note_new_el = $(e.target)
      note_title = $quick_note_new_el.val().trim()
      APP.justdo_quick_notes.addQuickNote({title: note_title})

      $quick_note_new_el.val ""

    return


Template.justdo_quick_notes_item.onRendered ->
  $(".quick-note").droppable
    tolerance: "pointer"
    drop: (e, ui) ->
      target_quick_note = Blaze.getData(ui.draggable[0])
      put_after_quick_note = Blaze.getData(e.target)
      completed = null

      if target_quick_note.completed and not put_after_quick_note.completed
        completed = false

      if not target_quick_note.completed and put_after_quick_note.completed
        completed = true

      if completed == null
        APP.justdo_quick_notes.reorderQuickNote(target_quick_note._id, put_after_quick_note._id)
      else
        APP.justdo_quick_notes.editQuickNote target_quick_note._id, {completed: completed}, (error) =>
          if error?
            JustdoSnackbar.show
              text: error.reason
          else
            APP.justdo_quick_notes.reorderQuickNote(target_quick_note._id, put_after_quick_note._id)

          return

      return

  $(".quick-note").draggable
    cursor: "none"
    helper: "clone"
    cancel: ".quick-note-mark, .quick-note-delete"
    refreshPositions: true
    start: (e, ui) ->
      $(ui.helper).width($(e.target).width())

      $(".slick-row").droppable
        tolerance: "pointer"
        drop: (e, ui) ->
          task_id = $(e.target).find(".grid-tree-control-task-id").attr("jd-tt").split("=")[1]
          quick_note = Blaze.getData(ui.draggable[0])

          APP.justdo_quick_notes.createTaskFromQuickNote quick_note._id, JD.activeJustdoId(), "/#{task_id}/", 0, (error, result) =>
            if error?
              JustdoSnackbar.show
                text: error.reason
            else
              # !!! NEED TO UPDATE - api cb returns /parent_id//task_id/
              console.log result

              JustdoSnackbar.show
                text: "Task has been created"
                duration: 5000
                actionText: "Undo"
                showDismissButton: true
                onActionClick: =>
                  # APP.justdo_quick_notes.undoCreateTaskFromQuickNote result, JD.activeJustdoId(), "/#{task_id}/", (error, result) =>
                  #   if error?
                  #     JustdoSnackbar.show
                  #       text: error.reason
                  #   else
                  #     JustdoSnackbar.close()
                  return

            return

          return

      return

    stop: (e, ui) ->
      $(".slick-row").droppable("destroy")

      return

  return


Template.justdo_quick_notes_item.events
  "mouseenter .quick-note, mouseleave .quick-note": (e, tpl) ->
    $(e.currentTarget).removeClass "mouse-down"
    $(e.currentTarget).draggable disabled: false

    return

  "mousedown .quick-note": (e, tpl) ->
    $(".quick-note").removeClass "active"
    $(e.currentTarget).addClass "mouse-down active"

    return

  "blur .quick-note": (e, tpl) ->
    $(e.currentTarget).removeClass "active"

    return

  "mouseup .quick-note": (e, tpl) ->
    $(e.currentTarget).removeClass "mouse-down"
    $(e.currentTarget).draggable disabled: true

    $title = $(e.currentTarget).find(".quick-note-title")
    $title.focus()

    if not $title.hasClass "active"
      if typeof window.getSelection != "undefined" && typeof document.createRange != "undefined"
        range = document.createRange()
        range.selectNodeContents($title[0])
        range.collapse(false)
        sel = window.getSelection()
        sel.removeAllRanges()
        sel.addRange(range)
        $title.addClass "active"

      else if typeof document.body.createTextRange != "undefined"
        textRange = document.body.createTextRange()
        textRange.moveToElementText($title[0])
        textRange.collapse(false)
        textRange.select()
        $title.addClass "active"

    return


  "blur .quick-note-title": (e, tpl) ->
    $el = $(e.currentTarget)
    $el.removeClass "active"

    note_id = @._id
    new_note_title = $el.text().trim()

    APP.justdo_quick_notes.editQuickNote note_id, {title: new_note_title}, (error) =>
      if error?
        JustdoSnackbar.show
          text: error.reason

    return

  "click .quick-note-mark": (e, tpl) ->
    $el = $(e.currentTarget)
    note = @
    completed = null
    delay = 40

    if note.completed?
      completed = false
    else
      completed = true
      delay = 160 # delay is equal to the CSS animation time for .quick-note-progress

    $el.parent().addClass("switching")

    if completed
      setTimeout ->
        $el.parent().removeClass("switching").addClass("completed")
      , delay * 2

    setTimeout ->
      APP.justdo_quick_notes.editQuickNote note._id, {completed: completed}, (error) =>
        if error?
          JustdoSnackbar.show
            text: error.reason

        return
    , delay * 4

    return

  "click .quick-note-delete": (e, tpl) ->
    note = @

    APP.justdo_quick_notes.editQuickNote note._id, {deleted: true}, (error) =>
      if error?
        JustdoSnackbar.show
          text: error.reason

      return

    return

















# ---------
