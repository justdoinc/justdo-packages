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
  tpl = @
  tpl.showCompleted = new ReactiveVar false
  tpl.completedQuickNotesLimit = new ReactiveVar 10
  tpl.showAddButton = new ReactiveVar false

  tpl.addQuickNote = ($el) ->
    note_title = $el.val().trim()
    APP.justdo_quick_notes.addQuickNote({title: note_title})
    $el.focus().val ""

    tpl.showAddButton.set false

    return

  # Subscription handles are managed by API.
  # To unsub simply call unsubscribeActiveQuickNotes()
  APP.justdo_quick_notes.subscribeActiveQuickNotes()

  @autorun ->
    if tpl.showCompleted.get()
      APP.justdo_quick_notes.subscribeCompletedQuickNotes({limit: tpl.completedQuickNotesLimit.get()})
    else
      APP.justdo_quick_notes.unsubscribeCompletedQuickNotes()

    return

  return

Template.justdo_quick_notes_dropdown.onRendered ->
  tpl = @

  $(".quick-note-add").focus()

  $(".quick-notes-list.completed").on "scroll", ->
    if $(this).scrollTop() + $(this).innerHeight() >= $(this)[0].scrollHeight

      completed_quick_notes_count = APP.collections.QuickNotes.find({completed: {$ne:null}}).count()
      completed_quick_notes_limit = tpl.completedQuickNotesLimit.get()

      if completed_quick_notes_limit <= completed_quick_notes_count
        tpl.completedQuickNotesLimit.set completed_quick_notes_limit + 10

    return

  return

Template.justdo_quick_notes_dropdown.helpers
  quickNotes: ->
    return APP.collections.QuickNotes.find({}, {sort: {order: -1}}).fetch()

  showCompleted: ->
    return Template.instance().showCompleted.get()

  activeQuickNotesExist: ->
    return APP.collections.QuickNotes.find({completed: null}).count()

  completedQuickNotesExist: ->
    return APP.collections.QuickNotes.find({completed: {$ne:null}}).count()

  showAddButton: ->
    return Template.instance().showAddButton.get()

Template.justdo_quick_notes_dropdown.events
  "click .quick-notes-completed-wrapper .quick-notes-list-title": (e, tpl) ->
    if not $(e.target).hasClass "quick-notes-completed-more"
      if tpl.showCompleted.get()
        tpl.showCompleted.set false
        $(".quick-notes-completed-dropdown-menu").removeClass "open"
      else
        tpl.showCompleted.set true

    return

  "keydown .quick-note-add": (e, tpl) ->
    if e.key == "Enter"
      e.preventDefault()
      tpl.addQuickNote $(e.target)

    return

  "keyup .quick-note-add": (e, tpl) ->
    $quick_note_add_input = $(e.target)

    if $quick_note_add_input.val()
      tpl.showAddButton.set true
    else
      tpl.showAddButton.set false

    return

  "click .quick-note-add-btn": (e, tpl) ->
    $quick_note_add_input = $(".quick-note-add")
    tpl.addQuickNote $quick_note_add_input

    return

  "click .quick-notes-completed-more": (e, tpl) ->
    if not tpl.showCompleted.get()
      tpl.showCompleted.set true
    else
      $(".quick-notes-completed-dropdown-menu").toggleClass "open"

    return

  "click .quick-notes-wrapper": (e, tpl) ->
    if not $(e.target).hasClass "quick-notes-completed-more"
      $(".quick-notes-completed-dropdown-menu").removeClass "open"

    return

  "click .quick-notes-completed-delete": (e, tpl) ->
    console.log "Delete all completed"

    $(".quick-notes-completed-dropdown-menu").removeClass "open"

    return

Template.justdo_quick_notes_dropdown.onDestroyed ->
  APP.justdo_quick_notes.unsubscribeActiveQuickNotes()
  APP.justdo_quick_notes.unsubscribeCompletedQuickNotes()

Template.justdo_quick_notes_item.onCreated ->
  # The non-reactive title helps to avoid issues with reactivity
  # When we change the note title and save it, reactivity kicks in,
  # and the title in contenteditable randomly gets duplicated

  @non_reactive_title = @data.title

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

  $(".quick-note-zero").droppable
    tolerance: "pointer"
    drop: (e, ui) ->
      target_quick_note = Blaze.getData(ui.draggable[0])
      completed = null

      if $(e.target).parent().hasClass "active"
        completed = false

      if $(e.target).parent().hasClass "completed"
        completed = true

      if completed == null
        APP.justdo_quick_notes.reorderQuickNote(target_quick_note._id)
      else
        APP.justdo_quick_notes.editQuickNote target_quick_note._id, {completed: completed}, (error) =>
          if error?
            JustdoSnackbar.show
              text: error.reason
          else
            APP.justdo_quick_notes.reorderQuickNote(target_quick_note._id)

          return

      return

  $(".quick-note").draggable
    cursor: "none"
    helper: "clone"
    cancel: ".quick-note-mark, .quick-note-delete"
    refreshPositions: true
    start: (e, ui) ->
      $(ui.helper).width($(e.target).width())

      $(".slick-cell.l0.r0").droppable
        tolerance: "pointer"
        addClasses: false
        hoverClass: "quick-note-droppable-cell"
        drop: (e, ui) ->
          # NEED TO UPDATE
          task_id = $(e.target).find(".grid-tree-control-task-id").attr("jd-tt").split("=")[1]
          quick_note = Blaze.getData(ui.draggable[0])

          APP.justdo_quick_notes.createTaskFromQuickNote quick_note._id, JD.activeJustdoId(), task_id, 0, (error, new_task_id) =>
            if error?
              JustdoSnackbar.show
                text: error.reason

              return

            rebuildProc = ->
              main_gc = APP.modules.project_page.mainGridControl()
              if not main_gc.getCollectionItemById(new_task_id)?
                # Item isn't yet part of the grid
                return

              APP.modules.project_page.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(new_task_id)

              main_gc._grid_data.off "rebuild", rebuildProc

              return

            APP.modules.project_page.mainGridControl()._grid_data.on "rebuild", rebuildProc

            JustdoSnackbar.show
              text: "Task has been created"
              duration: 5000
              actionText: "Undo"
              showDismissButton: true
              onActionClick: =>
                APP.justdo_quick_notes.undoCreateTaskFromQuickNote quick_note._id, JD.activeJustdoId(), "/#{task_id}/", (error) =>
                  if error?
                    JustdoSnackbar.show
                      text: error.reason

                JustdoSnackbar.close()

                return

            return

          return

      return

    stop: (e, ui) ->
      $(".slick-cell.l0.r0").droppable("destroy")

      return

  return

Template.justdo_quick_notes_item.helpers
  nonReactiveTitle: ->
    return Template.instance().non_reactive_title.replace(/\n/g, "<br>")

Template.justdo_quick_notes_item.events
  "mouseenter .quick-note, mouseleave .quick-note": (e, tpl) ->
    if not ($el = $(e.currentTarget)).hasClass "active"
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

  # The following is only relavent to editing quick note title
  "mouseup .quick-note-editable": (e, tpl) ->
    if ($el = $(e.currentTarget)).hasClass "mouse-down"
      $el.removeClass "mouse-down"
      $el.children(".quick-note-title").attr("contenteditable", true)
      $el.draggable disabled: true
      $title = $el.find(".quick-note-title")
      tpl.prev_note_title = $title.html()
      $title.focus()

      # Move text cursor to end of string
      if not $title.hasClass "active"
        if window.getSelection? document.createRange?
          range = document.createRange()
          range.selectNodeContents($title[0])
          range.collapse(false)
          sel = window.getSelection()
          sel.removeAllRanges()
          sel.addRange(range)
          $title.addClass "active"

        else if document.body.createTextRange?
          text_range = document.body.createTextRange()
          text_range.moveToElementText($title[0])
          text_range.collapse(false)
          text_range.select()
          $title.addClass "active"

    return

  "keydown .quick-note-title": (e, tpl) ->
    if e.key == "Enter" and !e.shiftKey
      e.preventDefault()
      $(e.currentTarget).blur()

    return

  "blur .quick-note-title": (e, tpl) ->
    $el = $(e.currentTarget)
    $el.attr "contenteditable", false
    $el.removeClass "active"

    note_id = @._id

    regex_space = new RegExp(/&nbsp;/g)
    regex_br = new RegExp(/<br\s*[\/]?>/gi)

    prev_note_title = tpl.prev_note_title.trim().replace(regex_br, "\n").replace(regex_space, " ")
    new_note_title = $el.html().trim().replace(regex_br, "\n").replace(regex_space, " ")

    if _.isEmpty new_note_title.trim()
      tpl.non_reactive_title = tpl.prev_note_title
      JustdoSnackbar.show
        text: "Quick note title cannot be empty"
      return

    if new_note_title isnt prev_note_title
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
