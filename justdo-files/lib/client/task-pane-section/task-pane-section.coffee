import {Promise} from "bluebird";

Template.task_pane_justdo_files_task_pane_section_section.onCreated ->
  @autorun =>
    if (active_item_id = APP.modules.project_page.activeItemId())?
      # Subscribe to tasks files
      Meteor.subscribe "jdfTaskFiles", active_item_id

    return

  return

Template.justdo_files_gallery.onCreated ->
  @renaming = new ReactiveVar false
  @deletion = new ReactiveVar false

  @getTypeCssClass = (file_type) ->
    [p1, p2] = file_type.split('/')
    if not p2?
      return p1
    else
      return p2.replace(/\./, "_")

    return

Template.justdo_files_gallery.helpers
  files: -> APP.justdo_files.tasks_files.find({"meta.task_id": APP.modules.project_page.activeItemId()})
  
  typeClass: -> Template.instance().getTypeCssClass(@file.type)
  
  renaming: -> Template.instance().renaming.get() == @file._id

  deletion: -> Template.instance().deletion.get() == @file._id

  size: -> JustdoHelpers.bytesToHumanReadable(@file.size)

  isImage: ->
    if (@file.type.slice(0,6) == "image/")
      return true

    return false

Template.justdo_files_gallery.events
  "click .file-rename-link": (e, tmpl) ->
    e.preventDefault()
    tmpl.renaming.set @file._id
    Meteor.defer ->
      tmpl.$("[name='title']").focus()

  "keypress [name='title']": (e, tmpl) ->
    if e.which == 13 # enter key
      tmpl.$('.file-rename-done').click()

  "click .file-rename-done": (e, tmpl) ->
    e.preventDefault()
    task = @task
    file = @file
    newTitle = tmpl.$("[name='title']").val()
    APP.justdo_files.renameFile file._id, newTitle, (err, result) ->
      if err
        console.log(err)
      else
        tmpl.renaming.set false
      return

  "click .file-rename-cancel": (e, tmpl) ->
    e.preventDefault()
    tmpl.renaming.set false

  "click .file-remove-link": (e, tmpl) ->
    e.preventDefault()
    tmpl.deletion.set @file._id

  "click .msg-ok": (e, tmpl) ->
    e.preventDefault()
    task = @task
    file = @file
    tmpl.$(".msg .msg-content").hide()
    tmpl.$(".loader").show()
    APP.justdo_files.removeFile file._id

  "click .msg-cancel": (e, tmpl) ->
    e.preventDefault()
    tmpl.deletion.set false

  "mouseenter .file": (e, tmpl) ->
    e.preventDefault()
    $(e.currentTarget).addClass "active"

  "mouseleave .file": (e, tmpl) ->
    e.preventDefault()
    $(".file").removeClass "active"

justdo_files_uploaders_state = {}

Template.justdo_files_uploader.onCreated ->
  @autorun =>
    if (active_item_id = APP.modules.project_page.activeItemId())?
      @prev_task_id = if @task_id? then @task_id else null
      @task_id = active_item_id
      if @prev_task_id?
        if @state.get() == "uploading"
          # save file upload process of previous task
          justdo_files_uploaders_state[@prev_task_id] =
            state: @state
            _upload_processes: @_upload_processes
        else
          # reset file upload process state of previous task
          justdo_files_uploaders_state[@prev_task_id] = null
          
      # load file upload process if there is one
      saved_state = justdo_files_uploaders_state[@task_id]
      if saved_state?
        _.extend @, saved_state
      else
        @dragenter_count = 0
        @state = new ReactiveVar "ready"
        @is_hovering = new ReactiveVar false

        @_upload_processes_dep = new Tracker.Dependency()
        @_upload_processes = []
    
    return

  @resetDropPane = ->
    @clearUploadProcesses()
    @awaiting_upload_promises_group = 0
    @state.set "ready"
    @is_hovering.set false
    @dragenter_count = 0

    return

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

    if tpl.state.get() != "uploading"
      tpl.resetDropPane()
      tpl.state.set "uploading"

    for file in files
      try 
        upload = APP.justdo_files.tasks_files.insert
          file: file
          meta:
            task_id: Tracker.nonreactive -> APP.modules.project_page.activeItemId()
          streams: "dynamic"
          chunkSize: "dynamic"
          transport: "ddp" # Need to find out why http doesn't work
        , false
      catch e
        # create a fake upload object to faciliate the message display 
        tpl.addUploadProcess
          file: file
          progress: new ReactiveVar 0
          state: new ReactiveVar "aborted"
          err_msg: e.reason

        return

      tpl.addUploadProcess(upload)

      upload.on "end", (err, file_obj) ->
        if err?
          if not upload.err_msg?
            upload.err_msg = if err.reason? then err.reason else err

        return

      upload.start()
    
    return

  return

Template.justdo_files_uploader.helpers
  getState: -> Template.instance().state.get()

  isHovering: ->     
    if Template.instance().is_hovering.get() == true
      return "hovering"
    return ""

  getUploadProcessMsg: ->
    tpl = Template.instance()

    upload_progress_state = _.map tpl.getUploadProcesses(), (upload) ->
      [
        if upload.state.get() == "completed" then 100 else upload.progress.get(),
        upload.state.get()
      ]

    active_uploads = _.filter(upload_progress_state, (res) -> res[1] not in ["completed", "aborted"])

    if active_uploads.length == 0
      tpl.state.set "ready"
      # Clear the input so re-attempt to upload the same file will work
      $("#file-input").val("")
      return ""

    total_percent_left = _.reduce upload_progress_state, (memo, cur) ->
      memo + cur[0]
    , 0

    return "Uploading files - #{(upload_progress_state.length - active_uploads.length)}/#{upload_progress_state.length} completed - " + Math.floor(total_percent_left / upload_progress_state.length) + "%"

  hasPreviousUploadResult: ->
    return Template.instance().getUploadProcesses().length > 0
  
  numSuccessfulUploads: ->
    _.reduce Template.instance().getUploadProcesses(), (memo, cur) ->
      if cur.state.get() == "completed"
        return memo + 1
      return memo
    , 0

  numFailedUploads: ->
    _.reduce Template.instance().getUploadProcesses(), (memo, cur) ->
      if cur.state.get() == "aborted"
        return memo + 1
      return memo
    , 0

  getFailedUploads: ->
    _.filter Template.instance().getUploadProcesses(), (upload) -> upload.state.get() == "aborted"

  noFiles: ->
    return APP.justdo_files.tasks_files.find({"meta.task_id": APP.modules.project_page.activeItemId()}).count() == 0


Template.justdo_files_uploader.events
  "change #file-input": (e, tpl) ->
    tpl.uploadFiles e.currentTarget.files

    return

  "dragenter .drop-pane": (e, tpl) ->
    tpl.dragenter_count++
    if tpl.dragenter_count == 1
      tpl.is_hovering.set true
    e.stopPropagation()
    e.preventDefault()
    return false

  "dragleave .drop-pane": (e, tpl) ->
    tpl.dragenter_count--
    if tpl.dragenter_count == 0
      tpl.is_hovering.set false
    e.stopPropagation()
    e.preventDefault()
    return false
  
  "dragover .drop-pane": (e, tpl) ->
    e.originalEvent.dataTransfer.dropEffect = 'copy'
    e.stopPropagation()
    e.preventDefault()
    return false
  
  "drop .drop-pane": (e, tpl) ->
    tpl.dragenter_count = 0
    tpl.is_hovering.set false
    tpl.uploadFiles e.originalEvent.dataTransfer.files
    e.stopPropagation()
    e.preventDefault()
    return false