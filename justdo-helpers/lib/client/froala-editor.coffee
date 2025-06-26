_.extend JustdoHelpers,
  _dataURLtoFile: (dataurl, filename) ->
    arr = dataurl.split(',')
    mime = arr[0].match(/:(.*?);/)[1]
    bstr = atob(arr[1])
    n = bstr.length
    u8arr = new Uint8Array(n)      
    while n-- 
      u8arr[n] = bstr.charCodeAt(n)
    return new File([u8arr], filename, {type:mime})

  _uploadFilesAndInsertToEditor: (file_upload_options, file_list, editor, type_to_insert, img_to_replace) ->
    file_upload_type = file_upload_options.type
    file_upload_destination = file_upload_options.destination
    file_upload_counter_rv = file_upload_options.counter_rv

    replaceEditorImageAndFile = (file, download_path) ->
      if type_to_insert is "image"
        if not img_to_replace?
          $org_img = $("img[temp_id=\"#{file.temp_id}\"]")
        else
          $org_img = $(img_to_replace)
        editor.image.insert download_path, false, {src: download_path}, $org_img,
          link: download_path
      else if type_to_insert is "file"
        editor.file.insert download_path, file.filename, null

    files = []
    for i in [0...file_list.length]
      ((i) ->
        file_item = file_list.item?(i) or file_list[i] 
        file_item.temp_id = Random.id()
        files.push file_item
        reader = new FileReader()
        reader.readAsDataURL(file_item)
        reader.onload = ->
          if type_to_insert is "image" and not img_to_replace?
            img = editor.image.insert reader.result, true,
              temp_id: file_item.temp_id
          return
        reader.onerror = (error) -> 
          console.log error
      )(i)
    
    if type_to_insert is "image"
      # While is_uploading_files isn't 0, the "done" button will show "uploading..." and disabled
      # For image uploads, we add the counter by two,
      # and minus one after uploading is finished, and after the editor's image is replaced with the uploaded version respectively.
      file_upload_counter_rv.set (Tracker.nonreactive -> file_upload_counter_rv.get() + 2)
    else if type_to_insert is "file"
      file_upload_counter_rv.set (Tracker.nonreactive -> file_upload_counter_rv.get() + 1)

    if env.TASKS_FILES_UPLOAD_ENABLED is "true" # Upload to Filestack if available
      APP.tasks_file_manager_plugin.tasks_file_manager.uploadFiles file_upload_destination, files, (err, uploaded_files) ->
        if err?
          console.log err
          file_upload_counter_rv.set (Tracker.nonreactive -> file_upload_counter_rv.get() - 1)
          return

        for file in uploaded_files
          file_id = file.url.substr(file.url.lastIndexOf("/")+1)
          download_path = APP.tasks_file_manager_plugin.tasks_file_manager.getFileDownloadPath file_upload_destination, file_id
          replaceEditorImageAndFile file, download_path
      
        file_upload_counter_rv.set (Tracker.nonreactive -> file_upload_counter_rv.get() - 1)
    else if env.JUSTDO_FILES_ENABLED is "true" # Upload to JustDo Files if available while Filestack isn't
      for file in files
        do (file) =>
          try
            upload = APP.justdo_files.uploadFile(file, file_upload_destination)
          catch e
            file_upload_counter_rv.set (Tracker.nonreactive -> file_upload_counter_rv.get() - 1)
            console.error e.reason or e
            return

          upload.on "end", (err, file_obj) ->
            file_upload_counter_rv.set (Tracker.nonreactive -> file_upload_counter_rv.get() - 1)
            if err?
              if not upload.err_msg?
                upload.err_msg = if err.reason? then err.reason else err
            file_id = file_obj._id
            file.filename = file_obj.name
            download_path = APP.justdo_files.getShareableLink(file_id)
            replaceEditorImageAndFile file, download_path

            return

          upload.start()

          return
    
    return
    
  # Create a FroalaEditor instance with common configuration and customization options
  # Refer to https://froala.com/wysiwyg-editor/docs/options/ for complete list of available options.
  # In addition, we support the following custom options:
  # fileUploadOptions:
  #   type: String # Not used yet. Provides future readiness with multiple file upload types.
  #   destination: String # The destination of the file upload.
  #   counter_rv: ReactiveVar # A reactive var to track the number of files being uploaded.

  createFroalaEditor: (selector, options = {}) ->
    check selector, String

    editor = null
    self = @

    # Default configuration
    default_options = 
      toolbarButtons: ["undo", "redo", "fontFamily", "fontSize", "bold", "italic", "underline", "strikeThrough", "color", "align", "formatUL", "formatOL", "quote", "clearFormatting", "insertLink", "insertTable"]
      tableStyles:
        "fr-no-borders": "No borders"
        "fr-dashed-borders": "Dashed Borders" 
        "fr-alternate-rows": "Alternate Rows"
      direction: if APP.justdo_i18n?.isRtl() then "rtl" else "ltr"
      quickInsertTags: []
      quickInsertButtons: ["embedly", "table", "ul", "ol", "hr"]
      toolbarSticky: false
      charCounterCount: false
      key: env.FROALA_ACTIVATION_KEY
      events: {}

    # Setup default file upload configuration
    if (file_upload_enabled = options.fileUpload)
      _file_upload_options_schema = new SimpleSchema
        type:
          type: String
        destination: 
          type: String
        counter_rv: 
          type: ReactiveVar

      {cleaned_val} =
        JustdoHelpers.simpleSchemaCleanAndValidate(
          _file_upload_options_schema,
          options.fileUploadOptions,
          {throw_on_error: true}
        )
      file_upload_options = cleaned_val
      file_upload_counter_rv = file_upload_options.counter_rv
      delete options.fileUploadOptions

      max_file_size_in_bytes = 0
      if env.TASKS_FILES_UPLOAD_ENABLED is "true"
        max_file_size_in_bytes = env.FILESTACK_MAX_FILE_SIZE_BYTES
      else if env.JUSTDO_FILES_ENABLED is "true"
        max_file_size_in_bytes = env.JUSTDO_FILES_MAX_FILESIZE

      files_upload_events = 
        "file.beforeUpload": (files) ->
          self._uploadFilesAndInsertToEditor file_upload_options, files, editor, "file"
          return false
        "file.error": (error, resp) ->
          console.log error
          return
        "image.beforePasteUpload": (img) ->
          file = self._dataURLtoFile img.src, Random.id()
          self._uploadFilesAndInsertToEditor file_upload_options, [file], editor, "image", img
          return false
        "image.beforeUpload": (images) ->
          self._uploadFilesAndInsertToEditor file_upload_options, images, editor, "image", null
          return false
        "image.loaded": (images, b, c) ->
          for image in images
            uploaded_files_count = (Tracker.nonreactive -> file_upload_counter_rv.get())
            if uploaded_files_count > 0 and /^http/.test image.currentSrc
              file_upload_counter_rv.set(uploaded_files_count - 1)
          return
        "image.error": (e, editor, error, resp) ->
          console.log error
          return
      
      # Add file upload configuration
      _.extend default_options,
        fileUpload: true
        fileMaxSize: max_file_size_in_bytes
        fileAllowedTypes: ["*"]
        imageMaxSize: max_file_size_in_bytes
        imageAllowedTypes: ["jpeg", "jpg", "png"]
        imageEditButtons: ['imageReplace', 'imageAlign', 'imageCaption', 'imageRemove', '|', 'imageLink', 'linkOpen', 'linkEdit', 'linkRemove', '-', 'imageDisplay', 'imageStyle', 'imageAlt', 'imageSize']
        events: files_upload_events

      # Add file upload buttons to toolbar if not already present
      if "insertImage" not in default_options.toolbarButtons
        default_options.toolbarButtons.push("insertImage")
      if "insertFile" not in default_options.toolbarButtons
        default_options.toolbarButtons.push("insertFile")
      
      # Add quick insert buttons to toolbar if not already present
      if "image" not in default_options.quickInsertButtons
        default_options.quickInsertButtons.unshift("image")
      if "video" not in default_options.quickInsertButtons
        default_options.quickInsertButtons.unshift("video")
    
    # Merge default options with custom options
    merged_options = _.extend {}, default_options, options
    # The extend above will override the events object in `default_options`. 
    # We need to extend it again to add the custom events.
    merged_options.events = _.extend {}, default_options.events, options.events

    # Create the FroalaEditor instance
    editor = new FroalaEditor selector, merged_options

    return editor 