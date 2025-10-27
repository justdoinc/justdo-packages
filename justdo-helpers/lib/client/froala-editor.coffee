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
    fs = APP.justdo_file_interface

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
        editor.file.insert download_path, file.name, null

    updateFileUploadCounterRv = (minus=false) ->
      # While is_uploading_files isn't 0, the "done" button will show "uploading..." and disabled
      # For image uploads, we add the counter by two,
      # and minus one after uploading is finished, and after the editor's image is replaced with the uploaded version respectively.
      if type_to_insert is "image"
        delta = 2
      else if type_to_insert is "file"
        delta = 1

      # If minus is true, we need to subtract the delta from the counter instead
      if minus
        delta = -delta

      file_upload_counter_rv.set (Tracker.nonreactive -> file_upload_counter_rv.get() + delta)
      return

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
    
    updateFileUploadCounterRv()

    for file in files
      do (file) =>
        fs.uploadBucketFolderFile file_upload_options.type, file_upload_options.destination, file, (err, file_obj) ->
          if err?
            console.error err
          else
            [jd_file_id_obj, additional_details] = file_obj
            link = fs.getFileLink jd_file_id_obj

            replaceEditorImageAndFile file, link # The `file` passed isn't the same as the `file_obj`

          updateFileUploadCounterRv true

          return

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

    fs = APP.justdo_file_interface
    editor = null
    self = @

    # Default configuration
    default_options = 
      toolbarButtons: ["undo", "redo", "fontFamily", "fontSize", "bold", "italic", "underline", "backgroundColor", "textColor", "align", "formatOL", "formatUL", "outdent", "indent", "quote", "clearFormatting", "insertLink", "insertTable",  "strikeThrough", "clearFormatting"]
      tableStyles:
        "fr-no-borders": "No borders"
        "fr-dashed-borders": "Dashed Borders" 
        "fr-alternate-rows": "Alternate Rows"
      fontFamily: _.extend FroalaEditor.DEFAULTS.fontFamily,
        "Space Mono,monospace": "Space Mono"
      direction: if APP.justdo_i18n?.isRtl() then "rtl" else "ltr"
      quickInsertTags: []
      quickInsertButtons: ["embedly", "table", "ul", "ol", "hr"]
      fileUpload: false
      imageUpload: false
      imagePaste: false
      toolbarSticky: false
      colorsHEXInput: false
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
      is_user_allowed_to_upload = fs.isUserAllowedToUploadBucketFolderFile(file_upload_options.type, file_upload_options.destination, Meteor.userId())
      file_size_limit = fs.getFileSizeLimit()
      _.extend default_options,
        fileUpload: is_user_allowed_to_upload
        imageUpload: is_user_allowed_to_upload
        imagePaste: is_user_allowed_to_upload
        fileMaxSize: file_size_limit
        fileAllowedTypes: ["*"]
        imageMaxSize: file_size_limit
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
