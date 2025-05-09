_.extend JustdoFiles.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerTaskPaneSection()

    return

  showPreviewOrStartDownload: (task_id, file) ->
    if APP.justdo_files.isFileTypePreviewable(file.type)
      # Show preview in bootbox

      message_template =
        JustdoHelpers.renderTemplateInNewNode(Template.justdo_files_files_preview, {task_id: task_id, file: file})

      bootbox.dialog
        title: file.name
        message: message_template.node
        animate: false
        className: "justdo-files-preview-dialog bootbox-new-design"

        onEscape: ->
          return true

        buttons:
          download:
            label: """<i class="fa fa-download" aria-hidden="true"></i> Download"""

            className: "btn-primary"

            callback: =>
              # Start download
              @downloadFile message_template.template_instance.active_file_rv.get()._id

          close:
            label: "Close"

            className: "btn-primary"

            callback: ->
              return true

    else
      # Start download
      @downloadFile file._id

  downloadFile: (file_id) ->
    check file_id, String
    download_link = new URL @getShareableLink(file_id)
    download_link.searchParams.append "download", true
    window.open download_link, "_blank"
    return

  # Upload a file to the task
  #
  # Returns a `FileUpload` object (Check https://github.com/veliovgroup/Meteor-Files/blob/master/docs/insert.md | https://archive.is/wip/MmVuS for more details)
  #
  # file: The file to upload
  # task_id: The task id to upload the file to
  # project_id: The project id to upload the file to
  #
  # project_id is optional, if not provided, the task's project_id will be used
  uploadFile: (file, task_id, project_id) ->
    check task_id, String
    check project_id, Match.Maybe String

    if not project_id?
      query_options = 
        fields:
          project_id: 1
      
      if not (task = Tracker.nonreactive -> APP.collections.Tasks.findOne(task_id, query_options))?
        throw @_error "unknown-task"

      project_id = task.project_id

    upload = APP.justdo_files.tasks_files.insert
      file: file
      meta:
        task_id: task_id
        project_id: project_id
      chunkSize: "dynamic"
      transport: "ddp"
    , false

    return upload

  getPreviewableFilesUnderTask: (task_id) ->
    query = 
      "meta.task_id": task_id
      type: 
        $in: JustdoFiles.preview_types_whitelist
    options = 
      sort: 
        "meta.upload_date": -1
        
    return APP.justdo_files.tasks_files.find(query, options).fetch()
