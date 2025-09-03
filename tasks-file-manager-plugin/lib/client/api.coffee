_.extend TasksFileManagerPlugin.prototype,
  _getEnvSpecificFsOptions: ->
    self = @
    
    ret = 
      uploadTaskFile: (file, options, cb) ->
        self.tasks_file_manager.uploadFiles options.task_id, [file], (err, uploaded_files) ->
          if err?
            cb err
            return

          uploaded_file = uploaded_files[0]
          # Normalize the file object to match the JustdoFiles file object
          uploaded_file._id = uploaded_file.url.substr(uploaded_file.url.lastIndexOf("/")+1)
          uploaded_file.name = uploaded_file.filename
          uploaded_file.type = uploaded_file.mimetype
          cb null, uploaded_file

        return
      subscribeToTaskFilesCollection: (options, cb) ->
        task_id = options.task_id
        return JD.subscribeItemsAugmentedFields [task_id], ["files"], {}, cb
      downloadTaskFile: (options) ->
        task_id = options.task_id
        file_id = options.file_id
        self.tasks_file_manager.downloadFile task_id, file_id, (err, url) ->
          if err
            console.log(err)
          return
        
        return
      showTaskFilePreviewOrStartDownload: (task_id, file, file_ids_to_show) ->
        if not _.isString file
          file = _.extend {}, file
        
        if (not file.id?) and (file._id?)
          file.id = file._id
        
        if (not file.title?) and (file.name?)
          file.title = file.name

        self.showPreviewOrStartDownload task_id, file, file_ids_to_show
    return ret

  showPreviewOrStartDownload: (task_id, file, file_ids_to_show) ->
    # file_ids_to_show is an optional array of file ids to limit the files shown in the preview dialog
    if _.isString file
      task = APP.collections.TasksAugmentedFields.findOne(task_id, {fields: {files: 1}})
      file = _.find task.files, (task_file) -> task_file.id is file
    
    if not _.isEmpty(file_ids_to_show) and (not _.find file_ids_to_show, (file_id) -> file_id is file.id)
      # Ensure the file to preview is in the file_ids_to_show
      # A deep copy is needed to avoid modifying the original array
      file_ids_to_show = Array.from file_ids_to_show
      file_ids_to_show.push file.id

    if @isFileTypePreviewable file.type
      # Show preview in bootbox

      message_template =
        JustdoHelpers.renderTemplateInNewNode(Template.tasks_file_manager_files_preview, {task_id: task_id, file: file, file_ids_to_show: file_ids_to_show})

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
