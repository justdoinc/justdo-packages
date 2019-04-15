Promise = require "bluebird"

APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  save_state = new ReactiveVar 0
  # save_state:
  #   0 - not required
  #   1 - save required
  #   2 - saving
  #   3 - saved
  #   4 - failed

  idle_save_timeout = null
  idle_save_timeout_ms = 3 * 1000 # 3 secs
  initIdleSaveTimeout = ->
    clearIdleSaveTimeout()

    idle_save_timeout = setTimeout ->
      save()
    , idle_save_timeout_ms
  
  clearIdleSaveTimeout = ->
    if idle_save_timeout?
      clearTimeout idle_save_timeout
      idle_save_timeout = null

  save_interval = null
  save_interval_ms = 20 * 1000
  initSaveInterval = ->
    if save_interval?
      # If already set, do nothing
      return

    save_interval = setInterval ->
      if save_state.get() == 1
        # save only if saved required
        save()
    , save_interval_ms

  clearSaveInterval = ->
    if save_interval?
      clearInterval save_interval
      save_interval = null

  save_count = 0
  save = ->
    save_state.set 2
    op =
      $set:
        description: $("#description-editor").froalaEditor("html.get")

    save_count += 1
    this_save_count = save_count
    do (this_save_count) ->
      APP.collections.Tasks.update task_id, op, (err) ->
        if save_state.get() == 2 and this_save_count == save_count
          # Change the save_state only if during saving state mode
          # and if no other save requests followed this save request.
          if err?
            save_state.set 4
          else
            save_state.set 3

  close_timeout = null
  close_timeout_ms = 60 * 1000 # 1 min
  initCloseTimeout = ->
    clearCloseTimeout()

    close_timeout = setTimeout ->
      closeEditor()
    , close_timeout_ms

  clearCloseTimeout = ->
    if close_timeout?
      clearTimeout close_timeout
      close_timeout = null
  
  getContainer = -> $("#task-description-container")

  relock_interval = null
  relock_interval_ms = Math.floor(close_timeout_ms * .5)
  lockTask = (task_id) ->
    lock = ->
      APP.collections.Tasks.update task_id,
        $set:
          description_lock:
            user: Meteor.userId()
            locked: TimeSync.getServerTime()
      , ->
        APP.logger.debug "Task #{task_id} description locked/relocked"

    lock_state = isLocked(task_id)
    if lock_state is null
      APP.logger.warn "Can't lock task, TimeSync out of sync"

      return false

    if lock_state == false
      # if not locked
      lock()

      if relock_interval?
        # If already set, do nothing
        return true

      relock_interval = setInterval ->
        lock()
      , relock_interval_ms

      return true
    else
      APP.logger.warn "Can't lock task #{task_id}, already locked by: #{JSON.stringify(lock)}"

      return false

  unlockTask = (task_id) ->
    if relock_interval?
      clearInterval relock_interval
      relock_interval = null

    APP.collections.Tasks.update task_id,
      $set:
        description_lock: null
    , ->
      # Note, if failed, lock will expiration will just take longer
      APP.logger.debug "Task #{task_id} description unlocked"

  isLocked = (task_id) ->
    # return null if TimeSync is out of sync
    # false if not locked
    # lock obj otherwise
    server_time = TimeSync.getServerTime() # note: reactive resource
    if not server_time?
      # TimeSync out of sync, can't check lock
      return null

    if not (task = project_page_module.activeItemObjFromCollection({description_lock: 1}))
      # We'll end up here if the task got removed and the grid is locked
      # We return false, as it reflects the deleted state better then
      # true
      return false

    description_lock = task.description_lock

    if description_lock? and
        (server_time - description_lock.locked) < close_timeout_ms and
        description_lock.user != Meteor.userId()
        # If locked by current user, then we allow editing, assuming tab got closed or refresh happened
      return description_lock

    return false

  edit_mode = new ReactiveVar false
  setEditMode = (mode) ->
    $container = getContainer()

    if mode == true
      edit_mode.set(true)
      $container.addClass("edit-mode")
    else
      edit_mode.set(false)
      $container.removeClass("edit-mode")

  task_id = null

  importEditor = ->
    loadCss = (url) ->
      $("head").append('<link href="' + url + '" rel="stylesheet">')

    loadJs = (url) ->
      new Promise (resolve, reject) =>
        $.getScript(url)
          .done =>
            resolve()
          .fail(( jqxhr, settings, exception ) => reject(exception))

    loadCss "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/css/froala_editor.min.css"
    loadCss "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.4.0/css/font-awesome.min.css"
    loadCss "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.25.0/codemirror.min.css"
    loadCss "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/css/plugins/colors.min.css"
    loadCss "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/css/plugins/table.min.css"
    loadCss "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/css/plugins/image.min.css"
    loadCss "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/css/plugins/fullscreen.min.css"

    
    Promise.each([
      "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.25.0/codemirror.min.js",
      "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.25.0/mode/xml/xml.min.js",
      "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/js/froala_editor.min.js"
      "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/js/plugins/colors.min.js",
      "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/js/plugins/table.min.js",
      "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/js/plugins/font_family.min.js",
      "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/js/plugins/font_size.min.js",
      "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/js/plugins/align.min.js",
      "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/js/plugins/image.min.js",
      "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/js/plugins/link.min.js",
      "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/js/plugins/lists.min.js",
      "https://cdn.jsdelivr.net/npm/froala-editor@2.9.3/js/plugins/fullscreen.min.js"
    ], (url) ->
      loadJs url
    )
      
  editor_importing = false
  editor_imported = false
  EDITOR_NOT_IMPORTED = 0
  EDITOR_IMPORITING = 1
  EDITOR_IMPORTED = 2
  editor_import_status = EDITOR_NOT_IMPORTED
  
  isEditorOpen = ->
    return $("#description-editor").data("froala.editor")?

  initEditor = ->
    if editor_import_status == EDITOR_IMPORITING # to make sure the editor is only imported once
      return Promise.reject("Editor is already importing")
    
    if editor_import_status == EDITOR_NOT_IMPORTED # to make sure the editor is only imported once
      editor_import_status = EDITOR_IMPORITING
      return importEditor().then =>
        editor_import_status = EDITOR_IMPORTED
      .catch =>
        editor_import_status = EDITOR_NOT_IMPORTED
    
    return Promise.resolve()
    
  openEditor = ->
    # Fetch the most recent version of task (for case grid-lock just released and
    # we have old version of it)
    if not (task = project_page_module.activeItemObjFromCollection({description: 1}))
      project_page_module.logger.debug "Task doesn't exist anymore"
      return

    # close editor if opened
    closeEditor()
    # check whether the task is locked
    task_locked = isLocked(task_id)
    if not task_locked?
      APP.logger.warn "Can't open task editor: Can't tell whether task is locked. Failed to obtain server time"
      return
    if task_locked != false
      APP.logger.warn "Task is locked, can't open editor"

      return

    # Lock task
    lockTask(task_id)

    initEditor().then =>  # editor will only be initialized once
      # set timeouts
      initCloseTimeout()
      initSaveInterval()
  
      # enable editor
      $("#description-editor").froalaEditor({
        toolbarButtons: ["fullscreen", "bold", "italic", "underline", "strikeThrough", "color", "insertTable", "fontFamily", "fontSize",
          "align", "formatUL", "formatOL", "quote", "insertLink", "insertImage", "clearFormatting", "undo", "redo"],
        heightMin: 200
      });
      
      # set editor content
      if task.description?
        $("#description-editor").froalaEditor("html.set", task.description)

      # set listener
      $("#description-editor").on "froalaEditor.contentChanged", (e, editor) =>
        if isEditorOpened()
          save_state.set 1
          initIdleSaveTimeout()
          initCloseTimeout()

      save_state.set 0
      setEditMode(true)
    .catch =>
      unlockTask(task_id)

  closeEditor = ->
    if isEditorOpen()
      # save
      save()
      # unlock task
      unlockTask(task_id)
      # clear timeouts and intervals
      clearIdleSaveTimeout()
      clearSaveInterval()
      clearCloseTimeout()
      # disable editor
      $("#description-editor").froalaEditor("destroy")

      setEditMode(false)

      # The following is in order to make sure, that by the
      # time we destroy the editor the grid control internal data
      # structures from which we derive the description, will have
      # the up-to-date description
      APP.modules.project_page.gridControl()?._grid_data?._flushAndRebuild()


  Template.task_pane_item_details_description.helpers
    edit_mode: -> edit_mode.get()
    save_state: -> save_state.get()
    description: -> @description?.replace(/\n/g, "")

  Template.task_pane_item_details_description_lock_message.helpers
    lock: -> isLocked(@_id)

  Template.task_pane_item_details_description.onCreated ->
    @autorun ->
      # On every path change, destroy the editor (closeEditor, saves current state)
      project_page_module.activeItemPath()
      closeEditor()
      task_id = project_page_module.activeItemId()

      return

    return

  Template.task_pane_item_details_description.events
    "click #add-description": (e) ->
      openEditor()

    "click #edit-description": (e) ->
      openEditor()

    "click #done-edit-description": (e) ->
      closeEditor()

    "click #save-description": (e) ->
      save()

    "click #description a": (e) ->
      e.preventDefault();
      url = $(e.target).attr "href"
      window.open(url, "_blank")

  Template.task_pane_item_details_description.onDestroyed ->
    closeEditor() # closeEditor takes care of saving
