_.extend JustdoFiles.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerTaskPaneSection()

    return

  _getEnvSpecificFsOptions: ->
    self = @
    
    ret = 
      uploadTaskFile: (file, task_id, cb) ->
        options = 
          task_id: task_id
        try
          upload = self.uploadFile(file, options)
        catch err
          cb err
          return

        upload.on "end", (err, file_obj) ->
          if err? and not upload.err_msg?
            upload.err_msg = err.reason or err
          
          cb err, file_obj

          return
        
        upload.start()

        return
      subscribeToTaskFilesCollection: (options, cb) ->
        task_id = options.task_id

        # Note: If cb is passed directly to the subscribeToTaskFilesCollection directly,
        # it's treated as the onReady callback, and the onStop callback is ignored.
        # As such, the cb will not be called with the error if the subscription fails.
        # So we need to use a sub_options object instead.
        is_on_ready_cb_called = false
        sub_options = 
          onReady: ->
            is_on_ready_cb_called = true
            cb?()
            return
          onStop: (err) ->
            if not is_on_ready_cb_called
              cb? err
            return
        
        return Meteor.subscribe "jdfTaskFiles", task_id, sub_options
      downloadTaskFile: (options) ->
        file_id = options.file_id
        self.downloadFile file_id
        return
      showTaskFilePreviewOrStartDownload: (task_id, file, file_ids_to_show) ->
        self.showPreviewOrStartDownload task_id, file, file_ids_to_show
    return ret

  showPreviewOrStartDownload: (task_id, file, file_ids_to_show) ->
    # file_ids_to_show is an optional array of file ids to limit the files shown in the preview dialog
    if _.isString file
      file = @tasks_files.find(file).fetch()[0]
    
    if not _.isEmpty(file_ids_to_show) and (not _.find file_ids_to_show, (file_id) -> file_id is file._id)
      # Ensure the file to preview is in the file_ids_to_show
      # A deep copy is needed to avoid modifying the original array
      file_ids_to_show = Array.from file_ids_to_show
      file_ids_to_show.push file._id

    if APP.justdo_files.isFileTypePreviewable(file.type)
      # Show preview in bootbox

      message_template =
        JustdoHelpers.renderTemplateInNewNode(Template.justdo_files_files_preview, {task_id: task_id, file: file, file_ids_to_show: file_ids_to_show})

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

  _uploadFileOptionsSchema: new SimpleSchema
    file:
      type: Match.OneOf File, Blob
    meta:
      type: Object
      blackbox: true
    collection_name:
      type: String
      allowedValues: JustdoFiles.supported_collection_names
    auto_start:
      type: Boolean
      optional: true
      defaultValue: false
  # Upload a file to the specified collection
  #
  # Returns a `FileUpload` object (Check https://github.com/veliovgroup/Meteor-Files/blob/master/docs/insert.md | https://archive.is/wip/MmVuS for more details)
  #
  # options:
  #   file: The file to upload
  #   meta: Metadata for the file
  #   collection_name: The collection to upload to (must be in JustdoFiles.supported_collection_names)
  #   auto_start: Whether to start the upload automatically (default: false)
  _uploadFile: (options) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_uploadFileOptionsSchema,
        options,
        {throw_on_error: true}
      )
    options = cleaned_val

    # Convert Blob to File if necessary
    if options.file instanceof Blob and not (options.file instanceof File)
      # Generate a default filename if not available
      filename = options.meta?.name or "untitled"
      # Create a new File from the Blob
      options.file = new File([options.file], filename, {type: options.file.type})

    default_file_upload_options = 
      chunkSize: "dynamic"
      transport: "ddp"

    file_upload_options = _.extend default_file_upload_options,
      file: options.file
    if options.meta?
      file_upload_options.meta = options.meta

    upload = @[options.collection_name].insert file_upload_options, options.auto_start

    return upload


  # file: The file to upload
  # task_id: The task id to upload the file to
  # project_id: The project id to upload the file to
  # project_id is optional, if not provided, the task's project_id will be used
  # meta: Metadata object for the file.
  # meta is optional. It's `task_id` and `project_id` will always be the same as the one in options.
  uploadFileOptionsSchema: new SimpleSchema
    task_id:
      type: String
    project_id:
      type: String
      optional: true
    meta:
      type: Object
      blackbox: true
      defaultValue: {}
  uploadFile: (file, options) ->
    check file, File
    
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @uploadFileOptionsSchema,
        options,
        {throw_on_error: true}
      )
    options = cleaned_val
    project_id = options.project_id
    task_id = options.task_id
    meta = options.meta

    if not project_id?
      query_options = 
        fields:
          project_id: 1
      
      if not (task = Tracker.nonreactive -> APP.collections.Tasks.findOne(task_id, query_options))?
        throw @_error "unknown-task"

      project_id = task.project_id

    file_upload_options =
      file: file
      meta: _.extend meta,
        task_id: task_id
        project_id: project_id
      collection_name: "tasks_files"

    upload = @_uploadFile file_upload_options

    return upload

  # avatar_image: The avatar image to upload
  uploadAvatar: (avatar_image) ->
    file_upload_options =
      file: avatar_image
      meta:
        is_avatar: true
      collection_name: "avatars_collection"

    upload = @_uploadFile file_upload_options

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
