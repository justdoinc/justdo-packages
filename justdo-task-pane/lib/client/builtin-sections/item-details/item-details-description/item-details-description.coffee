description_only_view_rv = new ReactiveVar false

getActiveTaskDescription = ->
  return APP.collections.TasksAugmentedFields.findOne(JD.activeItemId(), {fields: {description: 1}})?.description or ""

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
    if idle_save_timeout?
      clearTimeout idle_save_timeout

    save_state.set 1

    idle_save_timeout = setTimeout ->
      save()
    , idle_save_timeout_ms

  save_interval = null
  save_interval_ms = 20 * 1000
  setupSaveInterval = ->
    if save_interval?
      # If already set, do nothing
      return

    save_interval = setInterval ->
      if save_state.get() == 1
        # save only if saved required
        save()
    , save_interval_ms

  stopSaveInterval = ->
    if save_interval?
      clearInterval save_interval
      save_interval = null

  save_count = 0
  save = ->
    if idle_save_timeout?
      clearTimeout idle_save_timeout

    if current_description_editor
      save_state.set 2

      description = $("#description-editor").val()

      if description == ""
        op =
          $set:
            description: null
      else
        op =
          $set:
            description: description

      save_count += 1
      this_save_count = save_count
      do (this_save_count) ->
        APP.collections.Tasks.update current_description_editor.task_id, op, (err) ->
          if save_state.get() == 2 and this_save_count == save_count
            # Change the save_state only if during saving state mode
            # and if no other save requests followed this save request.
            if err?
              save_state.set 4
            else
              save_state.set 3

  uploading_files = new ReactiveVar 0

  destroy_timeout = null
  destroy_timeout_ms = 60 * 1000 # 1 min
  initDestroyTimeout = ->
    if destroy_timeout?
      clearTimeout destroy_timeout

    destroy_timeout = setTimeout ->
      destroyEditor()
    , destroy_timeout_ms

  getContainer = -> $("#task-description-container")

  relock_interval = null
  relock_interval_ms = Math.floor(destroy_timeout_ms * .5)
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
        (server_time - description_lock.locked) < destroy_timeout_ms and
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
  
  _uploadFilesAndInsertToEditor = (task_id, file_list, editor, type_to_insert, img_to_replace) ->
    files = []
    for i in [0...file_list.length]
      ((i) ->
        file_item = file_list.item?(i) or file_list[i] 
        file_item.temp_id = Random.id()
        files.push file_item
        reader = new FileReader()
        reader.readAsDataURL(file_item)
        reader.onload = -> 
          img = editor.image.insert reader.result, true,
            temp_id: file_item.temp_id
          return
        reader.onerror = (error) -> 
          console.log error
      )(i)
    
    uploading_files.set (Tracker.nonreactive -> uploading_files.get() + 2)
    APP.tasks_file_manager_plugin.tasks_file_manager.uploadFiles task_id, files, (err, uploaded_files) ->
      if err?
        console.log err
        uploading_files.set (Tracker.nonreactive -> uploading_files.get() - 1)
        return

      for file in uploaded_files
        file_id = file.url.substr(file.url.lastIndexOf("/")+1)
        download_path = APP.tasks_file_manager_plugin.tasks_file_manager.getFileDownloadPath task_id, file_id
        if type_to_insert == "image"
          if not $img_to_replace?
            $org_img = $("[data-temp_id=\"#{file.temp_id}\"]")
          else
            $org_img = $(img_to_replace)
          editor.image.insert download_path, false, {src: download_path}, $org_img,
            link: download_path
        else if type_to_insert == "file"
          editor.file.insert download_path, file.filename, null
      
      uploading_files.set (Tracker.nonreactive -> uploading_files.get() - 1)
    return

  dataURLtoFile = (dataurl, filename) ->
    arr = dataurl.split(',')
    mime = arr[0].match(/:(.*?);/)[1]
    bstr = atob(arr[1])
    n = bstr.length
    u8arr = new Uint8Array(n)      
    while n-- 
      u8arr[n] = bstr.charCodeAt(n)
    return new File([u8arr], filename, {type:mime})
    
  current_description_editor = null
  initEditor = ->
    # Fetch the most recent version of task (for case grid-lock just released and
    # we have old version of it)
    if not (task = project_page_module.activeItemObjFromCollection({description: 1}))
      project_page_module.logger.debug "Task doesn't exist anymore"
      return

    initDestroyTimeout()
    setupSaveInterval()

    $container = getContainer()

    # Force task description to be the most recent fetched-from-collection
    # description, for case we just got out of grid lock
    $("#description-editor", $container).val(getActiveTaskDescription())

    task_id =
      project_page_module.activeItemId()

    task_locked = isLocked(task_id)

    if not task_locked?
      APP.logger.warn "Can't open task editor: Can't tell whether task is locked. Failed to obtain server time"

      return

    if task_locked != false
      APP.logger.warn "Task is locked, can't open editor"

      return

    # Lock
    lockTask(task_id)

    $("#description-editor", $container)
      .one("froalaEditor.initialized", (e, editor) ->
        setEditMode(true)

        current_description_editor = editor

        editor.task_id = task_id

        save_state.set 0

        editor.html.set(getActiveTaskDescription())

        # set change listeners
        for change_event in ["contentChanged", "keydown"]
          editor.events.on change_event, (e) ->
            initIdleSaveTimeout()
            initDestroyTimeout()

            return
          , false # false for the 'first' argument: events.on (name, callback, [first])

        return
      )

    APP.getEnv (env) =>
      $("#description-editor", $container)
        .froalaEditor({
          toolbarButtons: ["bold", "italic", "underline", "strikeThrough", "color", "insertTable", "fontFamily", "fontSize",
            "align", "formatUL", "formatOL", "quote", "insertLink", "clearFormatting", "undo", "redo",
            "insertFile", "insertImage"
          ]
          imageEditButtons: ['imageReplace', 'imageAlign', 'imageCaption', 'imageRemove', '|', 'imageLink', 'linkOpen', 
            'linkEdit', 'linkRemove', '-', 'imageDisplay', 'imageStyle', 'imageAlt', 'imageSize']
          tableStyles:
            "fr-no-borders": "No borders"
            "fr-dashed-borders": "Dashed Borders"
            "fr-alternate-rows": "Alternate Rows"
          quickInsertTags: []
          charCounterCount: false
          key: env.FROALA_ACTIVATION_KEY
          fileUpload: true
          fileMaxSize: env.FILESTACK_MAX_FILE_SIZE_BYTES
          fileAllowedTypes: ["*"]
          imageMaxSize: env.FILESTACK_MAX_FILE_SIZE_BYTES
          imageAllowedTypes: ["jpeg", "jpg", "png"]
        })
        .on "froalaEditor.file.beforeUpload", (e, editor, files) ->
          _uploadFilesAndInsertToEditor task_id, files, editor, "file"
          return false
        .on "froalaEditor.file.error", (e, editor, error, resp) ->
          console.log error
          return
        .on "froalaEditor.image.beforePasteUpload", (e, editor, img) ->
          file = dataURLtoFile img.src, Random.id()
          _uploadFilesAndInsertToEditor task_id, [file], editor, "image", img
          return false
        .on "froalaEditor.image.beforeUpload", (e, editor, images) ->
          _uploadFilesAndInsertToEditor task_id, images, editor, "image", null
          return false
        .on "froalaEditor.image.loaded", (e, editor, images, b, c) ->
          for image in images
            uploaded_files_count = (Tracker.nonreactive -> uploading_files.get())
            if uploaded_files_count > 0 and /^http/.test image.currentSrc
              uploading_files.set(uploaded_files_count - 1)
        .on "froalaEditor.image.error", (e, editor, error, resp) ->
          console.log error
          return
        
        return

    return

  destroyEditor = ->
    if current_description_editor?
      stopSaveInterval()

      save()

      unlockTask(current_description_editor.task_id)

      # The following is in order to make sure, that by the
      # time we destroy the editor the grid control internal data
      # structures from which we derive the description, will have
      # the up-to-date descripion
      APP.modules.project_page.gridControl()?._grid_data?._flushAndRebuild()

      # if there's editor
      current_description_editor.destroy()
      current_description_editor = null

      setEditMode(false)

  Template.task_pane_item_details_description.helpers
    edit_mode: -> edit_mode.get()
    save_state: -> save_state.get()
    description: -> @description?.replace(/\n/g, "") # We found out that new lines can break rendering, removing them has no effect on the html rendering.
    uploading_files: -> uploading_files.get()
    description: -> getActiveTaskDescription()

  Template.task_pane_item_details_description_lock_message.helpers
    lock: -> isLocked(@_id)

  Template.task_pane_item_details_description.onCreated ->
    @autorun ->
      # On every path change, destroy the editor (destroyEditor, saves current state)
      project_page_module.activeItemPath()

      APP.projects.subscribeActiveTaskAugmentedFields(["description"])

      destroyEditor()

    return

  Template.task_pane_item_details_description.onRendered ->
    @autorun =>
      if description_only_view_rv.get()
        $(".task-pane-section-item-details-wrapper").addClass "description-only-view"
      else
        $(".task-pane-section-item-details-wrapper").removeClass "description-only-view"

      return

    return

  Template.task_pane_item_details_description.events
    "click #add-description": (e) ->
      initEditor()

    "click #edit-description": (e) ->
      initEditor()

    "click #done-edit-description": (e) ->
      destroyEditor()

    "click #save-description": (e) ->
      save()

    "click #description a": (e) ->
      e.preventDefault();
      url = $(e.target).attr "href"
      window.open(url, "_blank")

    "click .maximize-description": (e, tpl) ->
      description_only_view_rv.set not description_only_view_rv.get()

      return

  Template.task_pane_item_details_description.onDestroyed ->
    destroyEditor() # destroyEditor takes care of saving