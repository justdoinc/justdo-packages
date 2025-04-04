_.extend JustdoFiles.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerTaskPaneSection()

    return

  showPreviewOrStartDownload: (task_id, file) ->
    if JustdoFiles.preview_supported_formats_regex.test file.type
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
    download_link = new URL @tasks_files.findOne(file_id).link()
    download_link.searchParams.append "download", true
    window.open download_link, "_blank"
    return
