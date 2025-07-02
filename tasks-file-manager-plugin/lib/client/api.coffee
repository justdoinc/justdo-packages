_.extend TasksFileManagerPlugin.prototype,
  _getEnvSpecificFsOptions: ->
    self = @
    
    ret = 
      uploadFile: (file, options, cb) ->
        await self.tasks_file_manager.uploadFiles options.task_id, [file], (err, uploaded_files) ->
          if err?
            cb err
            return

          uploaded_file = uploaded_files[0]
          # Normalize the file object to match the JustdoFiles file object
          uploaded_file._id = uploaded_file.url.substr(uploaded_file.url.lastIndexOf("/")+1)
          cb null, uploaded_file

        return
      subscribeToFilesCollection: (options, cb) ->
        task_id = options.task_id
        return JD.subscribeItemsAugmentedFields [task_id], ["files"], {}, cb
      isFileExists: (options, cb) ->
        task_id = options.task_id
        file_id = options.file_id
        sub = @subscribeToFilesCollection {task_id: task_id}, (err) =>
          if err?
            cb err
          else
            exists = APP.collections.TasksAugmentedFields.findOne(@_getIsFileExistsQuery(options), @_getIsFileExistsQueryOptions())?
            sub.stop()
            cb null, exists
          
          return

        return
      downloadFile: (options) ->
        task_id = options.task_id
        file_id = options.file_id
        self.tasks_file_manager.downloadFile task_id, file_id, (err, url) ->
          if err
            console.log(err)
          return
        
        return
    return ret

  showPreviewOrStartDownload: (task_id, file) ->
    conv_matrix = @tasks_file_manager.getConversionMartix()
    preview_supported_formats = _.union conv_matrix["pdf"], conv_matrix["jpg"]

    if (file.type in preview_supported_formats) or (file.type.indexOf("video/") is 0)
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
              active_file_id = message_template.template_instance.active_file_rv.get().id
              APP.tasks_file_manager_plugin.tasks_file_manager.downloadFile task_id, active_file_id, (err, url) ->
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

    @custom_feature_maintainer.stop()

    @destroyed = true

    @logger.debug "Destroyed"

    return
