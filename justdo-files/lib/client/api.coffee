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
      uploadFile: (file, options, cb) ->
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

    return ret

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

    file_upload_options =
      file: file
      meta:
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
