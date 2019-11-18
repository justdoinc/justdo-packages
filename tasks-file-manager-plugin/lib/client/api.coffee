_.extend TasksFileManagerPlugin.prototype,
  showPreviewOrStartDownload: (task_id, file) ->
    preview_supported_formats = ["application/pdf", "image/png", "image/gif", "image/jpeg", "image/bmp"]

    if file.type in preview_supported_formats
      # Show preview in bootbox

      message_template =
        JustdoHelpers.renderTemplateInNewNode(Template.tasks_file_manager_files_preview, {task_id: task_id, file: file})

      bootbox.dialog
        title: file.title
        message: message_template.node
        animate: false
        className: "tasks-file-manager-preview-dialog bootbox-new-design"

        onEscape: ->
          return true

        buttons:
          download:
            label: "Download"
            className: "btn-primary"

            callback: =>
              # Start download
              APP.tasks_file_manager_plugin.tasks_file_manager.downloadFile task_id, file.id, (err, url) ->
                if err then console.log(err)

              return false # so the bootbox won't close

          close:
            label: "Close"
            className: "btn-secondary"

            callback: ->
              return true

    else
      # Start download
      APP.tasks_file_manager_plugin.tasks_file_manager.downloadFile task_id, file.id, (err, url) ->
        if err then console.log(err)

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
