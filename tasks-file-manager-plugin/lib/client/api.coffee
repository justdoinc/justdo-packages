_.extend TasksFileManagerPlugin.prototype,
  showPreviewOrStartDownload: (task_id, file) ->
    pics_embedder = (link, alt) ->
      """<img src="#{link}" alt="#{alt}" title="#{alt}" style="max-width: 100%;" />"""

    preview_supported_formats =
      "application/pdf":
        embedder: (link, alt) ->
          """<embed src="#{link}" width="970" height="550" alt="#{alt}" pluginspage="http://www.adobe.com/products/acrobat/readstep2.html">"""
      "image/png":
        embedder: pics_embedder
      "image/gif":
        embedder: pics_embedder
      "image/jpeg":
        embedder: pics_embedder
      "image/bmp":
        embedder: pics_embedder

    file_format = file.type
    if file_format of preview_supported_formats
      # Show preview in bootbox

      embedder = preview_supported_formats[file_format].embedder

      link = APP.tasks_file_manager_plugin.tasks_file_manager.getDownloadLink task_id, file.id, (err, link) ->
        bootbox.dialog
          title: file.title
          message: """
            #{embedder(link, file.title)}
          """
          animate: false
          className: "tasks-file-manager-preview-dialog"

          onEscape: ->
            return true

          buttons:
            download:
              label: """<i class="fa fa-download" aria-hidden="true"></i> Download"""

              className: "btn-primary"

              callback: =>
                # Start download
                APP.tasks_file_manager_plugin.tasks_file_manager.downloadFile task_id, file.id, (err, url) ->
                  if err then console.log(err)

                return false # so the bootbox won't close

            close:
              label: "Close"

              className: "btn-primary"

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