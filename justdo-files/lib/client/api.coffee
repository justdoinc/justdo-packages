_.extend JustdoFiles.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerTaskPaneSection()

    return

  showPreviewOrStartDownload: (task_id, file) ->
    preview_supported_formats = ["application/pdf", "image/png", "image/gif", "image/jpeg", "image/bmp"]

    if file.type in preview_supported_formats
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
              APP.justdo_files.downloadFile file._id

          close:
            label: "Close"

            className: "btn-primary"

            callback: ->
              return true

    else
      # Start download
      APP.justdo_files.downloadFile file._id

  downloadFile: (file_id) ->
    window.location.href = APP.justdo_files.tasks_files.findOne(file_id).link()
