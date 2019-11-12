TasksFileManager.DropPane = (task_id, manager) ->
  @task_id = task_id
  @manager = manager
  @_status = new ReactiveVar("loading")
  @_error = new ReactiveVar(null)
  @_progress = new ReactiveVar(0)

  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      @destroy()

  # @_init() in an isolated
  # computation to avoid our init procedures from affecting
  # the encapsulating computation (if any)
  Tracker.nonreactive =>
    @_init()

_.extend TasksFileManager.DropPane.prototype,
  _init: -> return

  # Attach this drop pane to a particular dom element, files dropped on that
  # element will be uploaded, and if the element is clicked a picker will open
  # allowing users to upload files from their computer and other sources.
  initPane: (element) ->
    @element = element

    @_initElement()

    refresh = =>
      if APP.filestack_base.filepicker?
        @refreshToken()
      else
        APP.filestack_base.once 'filestack-ready', => @refreshToken()

    # Immediately refresh the token
    refresh()

    # Refresh the token every 15 minutes, it expires once an hour
    @timerHandle = setInterval refresh, 1000 * 60 * 15

  _initElement: () ->

    $element = $(@element)

    # Open picker on click
    $element.click => @openPicker()

    # XXX prevent drag-drop when pane is uploading files?

    # http://stackoverflow.com/a/21002544/2391620
    drag_enter_counter = 0

    $element.on 'dragenter', (e) =>
      drag_enter_counter++
      if drag_enter_counter > 0
        @_status.set "hovering"

      e.stopPropagation()
      e.preventDefault()

      return false

    $element.on 'dragleave', (e) =>
      drag_enter_counter--

      if drag_enter_counter <= 0
        @_progress.set(0)
        @_status.set "ready"
        @_error.set null

      e.stopPropagation()
      e.preventDefault()

      return false

    $element.on 'dragover', (e) =>

      e.originalEvent.dataTransfer.dropEffect = 'copy'

      e.preventDefault()
      return false

    $element.on 'drop', (e) =>
      drag_enter_counter = 0

      try
        e.stopPropagation()
        e.preventDefault()
      catch err
        console.error(err)

      try
        if @_isFolderDropped(e)
          @_onError @task_id, "drop-folder", "Folders can't be uploaded"

        files = e.originalEvent.dataTransfer.files
        imgSrc = @_getImageSrcDrop e.originalEvent.dataTransfer

        if files.length
          @_uploadDroppedFiles files
        else if imgSrc?
          @_uploadDroppedImage imgSrc
        else
          @_onError @task_id, "drop-other", "Nothing to upload"

      catch err

        console.error(err)
        @_onError @task_id, "unknown-error", "An error occurred: " + e

  _isFolderDropped: (event) ->
    # From filepicker.js
    `
      var entry,
          items,
          i;

      if (event.dataTransfer.items) {
          items = event.dataTransfer.items;
          for (i = 0; i < items.length; i++) {
              entry = items[i] && items[i].webkitGetAsEntry ? items[i].webkitGetAsEntry() : undefined;

              if (entry && !!entry.isDirectory) {
                  console.log("Error in _isFolderDropped: upload is folder.")
                  return true;
              }
          }
      }
      return false;
    `

  _getImageSrcDrop: (dataTransfer) ->
    # from filepicker.js
    `
      var url, matched;

      if (dataTransfer && typeof dataTransfer.getData === 'function') {
          url = dataTransfer.getData('text');

          try {
              // invalid 'text/html' arg on IE10
              url = url || dataTransfer.getData('text/html');
          } catch(e) {
              console.log("Error in _getImageSrcDrop:", e)
          }

          if (url && !url.match(/^(http|https)\:.*\/\//i)){
              matched = url.match(/<img.*?src="(.*?)"/i);
              url = matched && matched.length > 1 ? matched[1] : null;
          }

      }
      return url;
    `

  _uploadDroppedFiles: (files) ->
    task_id = @task_id

    upload_options =
      signature: @_policy.signature
      policy: @_policy.policy

    _.extend upload_options, @manager.getStorageLocationAndPath(task_id)

    total_files = files.length
    progresses = []
    uploaded = []

    _.each files, (file, i) =>
      APP.filestack_base.filepicker.store(
        file
      ,
        upload_options
      , (blob) =>
          uploaded.push(blob)

          if uploaded.length == total_files
            @_onSuccess task_id, uploaded
      , (error) =>
          @_onError task_id, "UploadError", error.toString()
      ,
        (progress) =>

          progresses[i] = progress
          total_progress = (_.reduce progresses, (a, b) => (a || 0) + (b || 0)) / total_files

          @_onProgress task_id, total_progress
    )

  # Refreshes the security token necessary to upload files to filestack, this
  # method is called periodically after you init the pane using `initPane`.
  refreshToken: ->
    if @destroyed
      return

    @manager.getUploadPolicy @task_id, (error, policy) =>
      if error
        # I considered adding some retry logic here and not setting the error
        # state and message until after n number of retries have been reached,
        # however, I believe that meteor already handles network errors, and
        # any other error is probably an actual error.
        @_status.set "error"
        @_error.set error
        return

      if not policy
        @_status.set "loading"
        @_error.set null
        return

      @_policy = policy
      @refreshPane()

      return

    return

  _onSuccess: (task_id, files) ->
    if task_id == @task_id
      @_status.set 'success'
      @_progress.set 100

    # XXX what to do if task manager no longer showes this task

    @manager.registerUploadedFiles task_id, files

  _onError: (task_id, type, message) ->
    if _.isObject(type)
      message = type.message
      type = type.code

    if type == 101
      # User just closed the dialog without doing anything, not really an issue
      return

    if task_id == @task_id
      # Don't change the @_progress variable, if the progress bar is shown in
      # case of an error, it should probably retain the last set value
      @_status.set 'error'

      error = new Error message
      error.type = type
      @_error.set error
    else
      bootbox.alert("File upload failed! Task Id: #{task_id}, Error: #{type} - #{message}")

  _onProgress: (task_id, percentage) ->
    if task_id == @task_id
      @_status.set 'uploading'
      @_progress.set percentage

  setTaskId: (task_id) ->
    if task_id != @task_id
      @task_id = task_id
      @_policy = null
      @resetPane()

  # Reset pane variables to their default/correct state, for example to clear
  # out any error message from a recent upload error.
  resetPane: () ->
    @_progress.set 0
    @_error.set null
    if @_policy
      @_status.set 'ready'
    else
      @_status.set 'loading'
      @refreshToken()

  # Resets the filestack integration for this pane, called periodically once
  # you init the pane using `initPane` (to keep the security token up to date)
  refreshPane: () ->
    if @destroyed
      return
    task_id = @task_id

    @_progress.set(0)
    @_status.set "ready"
    @_error.set null

  # Open a filepicker dialog to allow the user to select and upload files from
  # their computer and other sources, called automatically if the user clicks
  # on the drop pane (the element you pass to `initPane`) but you can also call
  # this method directly if you want the picker to show under other
  # circumstances or choose not to show a drop pane at all (never called
  # `initPane`)
  openPicker: () ->
    _openPicker = (policy) =>
      APP.filestack_base.filepicker.pickAndStore {
        signature: policy.signature
        policy: policy.policy
        multiple: true
      }, @manager.getStorageLocationAndPath(@task_id), @_onSuccess.bind(@, @task_id), @_onError.bind(@, @task_id), @_onProgress.bind(@, @task_id)

    if @_policy
      _openPicker @_policy
    else
      @manager.getUploadPolicy @task_id, (error, policy) =>
        if error
          @_status.set "error"
          @_error.set error
          return

        @_policy = policy
        _openPicker @_policy

  # Current status of the pane, one of:
  # loading - currently fetching an upload token, or `initPane` hasn't been
  #           called yet.
  # ready - pane is ready for files to be uploaded
  # uploading - one or more files are currently being uploaded
  # success - one or more files was uploaded successfully
  # error - there was an error of some kind
  #
  # Call resetPane to reset this variable back to it's default state ('ready',
  # unless still fetching the upload token, in which case 'loading')
  status: () -> @_status.get()

  # A number from 0 to 100, supplied by filestack, which indicates the upload
  # progress.
  #
  # Call resetPane to reset this variable back to it's default state (0)
  progress: () -> @_progress.get()

  # The current error, if any
  #
  # Call resetPane to reset this variable back to it's default state (null)
  error: () -> @_error.get()

  destroy: () ->
    @destroyed = true
    clearInterval @timerHandle
    delete @element
    return;
