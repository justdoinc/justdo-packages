Template.task_pane_justdo_files_task_pane_section_section.onCreated ->
  @autorun =>
    if (active_item_id = APP.modules.project_page.activeItemId())?
      # Subscribe to tasks files
      Meteor.subscribe "jdfTaskFiles", active_item_id

    return

  return

Template.justdo_files_gallery.helpers
  files: ->
    return APP.justdo_files.tasks_files.find({"meta.task_id": APP.modules.project_page.activeItemId()})

Template.justdo_files_gallery.events
  "click .remove-file": ->
    file_id = @_id

    bootbox.confirm
      message: "Are you sure you want to remove this file?"
      className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
      closeButton: false

      callback: (result) ->
        if result
          APP.justdo_files.removeFile file_id

          return

        return

    return

dragenter_count = 0

Template.justdo_files_uploader.onCreated ->
  dragenter_count = 0
  @state = new ReactiveVar "ready"

  @_upload_processes_dep = new Tracker.Dependency()
  @_upload_processes = []

  @clearUploadProcesses = ->
    if @_upload_processes.length > 0 # this prevents infinite loop
      @_upload_processes = []
      @_upload_processes_dep.changed()

    return 

  @addUploadProcess = (upload_process) =>    
    @_upload_processes.push(upload_process)

    @_upload_processes_dep.changed()

    return

  @getUploadProcesses = =>
    @_upload_processes_dep.depend()

    return @_upload_processes

  @uploadFiles = (files) =>
    tpl = @

    tpl.state.set "uploading"
    for file in files
      do (file) ->
        upload = APP.justdo_files.tasks_files.insert
          file: file
          meta:
            task_id: Tracker.nonreactive -> APP.modules.project_page.activeItemId()
          streams: "dynamic"
          chunkSize: "dynamic"
          transport: "ddp" # Need to find out why http doesn't work
        , false

        tpl.addUploadProcess(upload)

        upload.on "end", (err, file_obj) ->
          if err?
            bootbox.alert
              message: "Error: " + err.reason
              className: "bootbox-new-design email-verification-prompt-alerts"
              closeButton: false

          tpl.state.set "ready"
          tpl.clearUploadProcesses()
          # Clear the input so re-attempt to upload the same file will work
          $("#file-input").val("")

          return

        upload.start()

        return

    return

  @autorun =>
    # Clear _upload_processes on task change
    APP.modules.project_page.activeItemId()

    @clearUploadProcesses()

    return

  return

Template.justdo_files_uploader.helpers
  uploadMessage: ->  
    tpl = Template.instance()

    switch tpl.state.get()
      when "ready"
        return "Drop files here or click to upload"
      when "hovering"
        return "Drop to upload"
      when "uploading"
        upload_progress_state = _.map tpl.getUploadProcesses(), (upload) ->
          [
            if upload.state.get() == "completed" then 100 else upload.progress.get(),
            upload.state.get()
          ]

        active_uploads = _.filter(upload_progress_state, (res) -> res[1] not in ["completed", "aborted"])
        total_percent_left = _.reduce upload_progress_state, (memo, cur) ->
          memo + cur[0]
        , 0

        return "Uploading files - #{(upload_progress_state.length - active_uploads.length)}/#{upload_progress_state.length} completed - %" + Math.floor(total_percent_left / upload_progress_state.length)

    return ""

Template.justdo_files_uploader.events
  "change #file-input": (e, tpl) ->
    tpl.uploadFiles e.currentTarget.files

    return

  "dragenter .drop-pane": (e, tpl) ->
    # what if uploading
    dragenter_count++
    if dragenter_count == 1
      tpl.state.set "hovering"
    e.stopPropagation()
    e.preventDefault()
    return false

  "dragleave .drop-pane": (e, tpl) ->
    dragenter_count--
    if dragenter_count == 0
      tpl.state.set "ready"
    e.stopPropagation()
    e.preventDefault()
    return false
  
  "dragover .drop-pane": (e, tpl) ->
    e.originalEvent.dataTransfer.dropEffect = 'copy'
    e.stopPropagation()
    e.preventDefault()
    return false
  
  "drop .drop-pane": (e, tpl) ->
    dragenter_count = 0
    tpl.uploadFiles e.originalEvent.dataTransfer.files
    e.stopPropagation()
    e.preventDefault()
    return false