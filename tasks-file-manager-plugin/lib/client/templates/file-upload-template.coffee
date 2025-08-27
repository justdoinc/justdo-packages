Template.tasks_file_manager_file_upload.onCreated ->
  @fs = APP.justdo_file_interface.cloneWithForcedFs "#{TasksFileManagerPlugin.fs_id}-tasks-files"
  @pickerPane = APP.tasks_file_manager_plugin.tasks_file_manager.makeDropPane @data.task_id
  @autorun =>
    task_id = Template.currentData().task_id
    @pickerPane.setTaskId task_id;

Template.tasks_file_manager_file_upload.onRendered ->
  if @pickerPane
    @pickerPane.initPane @$(".drop-pane")[0]

Template.tasks_file_manager_file_upload.onDestroyed ->
  if @pickerPane?
    @pickerPane.destroy()

Template.tasks_file_manager_file_upload.helpers
  getFileSizeLimit: -> Template.instance().fs.getFileSizeLimit()

  uploadMessage: ->
    tmpl = Template.instance()
    state = tmpl.pickerPane.status()
    return switch state
      when "loading"
        ""
      when "ready"
        "Drop files here or click to upload"
      when "hovering"
        "Drop to upload"
      when "success"
        "File uploaded! Click or drop to upload another"
      when "error"
        tmpl.pickerPane.error()
      when "uploading"
        "Uploading..."

  hoverClass: ->
    tmpl = Template.instance()
    state = tmpl.pickerPane.status()
    return "drop-pane-hover" if state == "hovering"

  filesClass: ->
    files = Template.instance().data.files
    if !files? or files?.length == 0
      return "no-files"
