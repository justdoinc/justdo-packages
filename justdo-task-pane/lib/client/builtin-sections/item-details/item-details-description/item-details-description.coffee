description_only_view_rv = new ReactiveVar false

getActiveTaskDescription = ->
  return APP.collections.TasksAugmentedFields.findOne(JD.activeItemId(), {fields: {description: 1}})?.description or ""

APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page
  task_id = null

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
        APP.collections.Tasks.update task_id, op, (err) ->
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
      is_file_upload_in_progress = Tracker.nonreactive -> uploading_files.get() > 0
      # Since file upload may take a while, 
      # we need to reset the destroy timeout to prevent the editor being destroyed while the upload is in progress.
      if is_file_upload_in_progress
        initDestroyTimeout()
      else
        destroyEditor()
      
      return
    , destroy_timeout_ms

    return

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

    current_description_editor = JustdoHelpers.createFroalaEditor "#description-editor", 
      fileUpload: true
      fileUploadOptions: 
        type: "tasks"
        destination: task_id
        counter_rv: uploading_files
      placeholderText: TAPi18n.__ "description_editor_placeholder_text"
      events:
        "initialized": ->
          setEditMode(true)
          save_state.set 0

          current_description_editor.html.set(getActiveTaskDescription())

          # set change listeners
          for change_event in ["contentChanged", "keydown"]
            current_description_editor.events.on change_event, (e) ->
              initIdleSaveTimeout()
              initDestroyTimeout()

              return
            , false # false for the 'first' argument: events.on (name, callback, [first])

          return

    return

  destroyEditor = ->
    if current_description_editor?
      stopSaveInterval()

      save()

      unlockTask(task_id)

      # The following is in order to make sure, that by the
      # time we destroy the editor the grid control internal data
      # structures from which we derive the description, will have
      # the up-to-date descripion
      APP.modules.project_page.gridControl()?._grid_data?._flushAndRebuild()

      # if there's editor
      current_description_editor.destroy()
      # Upon destroy, FroalaEditor adds the `display: block` to the element. We need to remove it.
      $("#description-editor").css("display", "")
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
    @autorun =>
      # On every path change, destroy the editor (destroyEditor, saves current state)
      project_page_module.activeItemPath()
      
      fs = APP.justdo_file_interface
      fs_id = fs.getDefaultFsId()
      @files_sub_handle = fs.subscribeToTaskFiles fs_id, JD.activeItemId()

      @task_descrioption_sub_handle = APP.projects.subscribeActiveTaskAugmentedFields(["description"])

      destroyEditor()

      return

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

    "click #task-description-container a": (e) ->
      e.preventDefault();
      url = $(e.target).attr "href"
      window.open(url, "_blank")
      return

    "click .maximize-description": (e, tpl) ->
      description_only_view_rv.set not description_only_view_rv.get()

      return

  Template.task_pane_item_details_description.onDestroyed ->
    destroyEditor() # destroyEditor takes care of saving
    @task_descrioption_sub_handle.stop()
    @files_sub_handle.stop()

    return