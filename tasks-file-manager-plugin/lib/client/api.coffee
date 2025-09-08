_.extend TasksFileManagerPlugin.prototype,
  _getEnvSpecificFsOptions: ->
    self = @

    # Currently used only with justdo-file-interface
    tasks_file_collection = new Mongo.Collection TasksFileManagerPlugin.tasks_files_collection_name
    
    ret = 
      getFileSizeLimit: -> 
        return env.FILESTACK_MAX_FILE_SIZE_BYTES
      getTaskFileLink: (task_id, file_id) ->
        return self.tasks_file_manager.getFileDownloadPath task_id, file_id
      isFileTypePreviewable: (file_type) ->
        return self.isFileTypePreviewable file_type
      isUserAllowedToUploadTaskFile: (task_id, user_id) ->
        permissions = [
          "task-field-edit.#{TasksFileManager.files_count_field_id}",
          "task-field-edit.files"
        ]
        return APP.justdo_permissions.checkTaskPermissions permissions, task_id, user_id
      uploadTaskFile: (task_id, file, cb) ->
        self.tasks_file_manager.uploadFiles task_id, [file], (err, uploaded_files) ->
          if err?
            cb err
            return

          uploaded_file = uploaded_files[0]
          
          # Normalize the file object to match the JustdoFiles file object
          normalized_uploaded_file = 
            _id: uploaded_file.url.substr(uploaded_file.url.lastIndexOf("/")+1)
            name: uploaded_file.filename
            type: uploaded_file.mimetype
            size: uploaded_file.size
          cb null, normalized_uploaded_file

        return
      subscribeToBucketFolder: (bucket_id, folder_name, callbacks) ->
        if bucket_id isnt "tasks"
          throw self._error "not-supported", "No publication exists for bucket #{bucket_id}"
        publication_name = TasksFileManagerPlugin.tasks_files_publication_name
        return Meteor.subscribe publication_name, folder_name, callbacks
      getBucketFolderFiles: (bucket_id, folder_name, query, query_options) ->
        if bucket_id isnt "tasks"
          throw self._error "not-supported", "No collection exists for bucket #{bucket_id}"
        collection_name = TasksFileManagerPlugin.tasks_files_collection_name
        query = _.extend query,
          task_id: folder_name
        return self[collection_name].find(query, query_options).fetch()
      downloadTaskFile: (task_id, file_id) ->
        self.tasks_file_manager.downloadFile task_id, file_id, (err, url) ->
          if err
            console.log(err)
          return
        
        return
      showTaskFilePreviewOrStartDownload: (task_id, file, file_ids_to_show) ->
        if _.isString file
          file = tasks_file_collection.findOne(file)
        else
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
