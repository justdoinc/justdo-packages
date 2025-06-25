_.extend JustdoHelpers,
  # Create a FroalaEditor instance with common configuration and customization options
  # Refer to https://froala.com/wysiwyg-editor/docs/options/ for complete list of available options.
  createFroalaEditor: (selector, options = {}) ->
    check selector, String

    # Default toolbar configuration
    default_toolbar_buttons = ["undo", "redo", "fontFamily", "fontSize", "bold", "italic", "underline", "strikeThrough", 
      "color", "align", "formatUL", "formatOL", "quote", "clearFormatting", "insertLink", "insertTable"]
    
    # Default configuration
    default_options = 
      toolbarButtons: options.toolbarButtons or default_toolbar_buttons
      tableStyles:
        "fr-no-borders": "No borders"
        "fr-dashed-borders": "Dashed Borders" 
        "fr-alternate-rows": "Alternate Rows"
      quickInsertTags: []
      toolbarSticky: false
      charCounterCount: false
      key: env.FROALA_ACTIVATION_KEY
      events: {}
    
    # Setup default file upload configuration
    if options.fileUpload
      max_file_size_in_bytes = 0
      if env.TASKS_FILES_UPLOAD_ENABLED is "true"
        max_file_size_in_bytes = env.FILESTACK_MAX_FILE_SIZE_BYTES
      else if env.JUSTDO_FILES_ENABLED is "true"
        max_file_size_in_bytes = env.JUSTDO_FILES_MAX_FILESIZE

      # Add file upload configuration
      _.extend default_options,
        fileUpload: true
        fileMaxSize: max_file_size_in_bytes
        fileAllowedTypes: ["*"]
        imageMaxSize: max_file_size_in_bytes
        imageAllowedTypes: ["jpeg", "jpg", "png"]
        imageEditButtons: ['imageReplace', 'imageAlign', 'imageCaption', 'imageRemove', '|', 'imageLink', 'linkOpen', 'linkEdit', 'linkRemove', '-', 'imageDisplay', 'imageStyle', 'imageAlt', 'imageSize']

      # Add file upload buttons to toolbar if not already present
      if "insertImage" not in default_options.toolbarButtons
        default_options.toolbarButtons.push("insertImage")
      if "insertFile" not in default_options.toolbarButtons
        default_options.toolbarButtons.push("insertFile")
    
    # Merge default options with custom options
    options = _.extend {}, default_options, options
    options.direction = if APP.justdo_i18n?.isRtl() then "rtl" else "ltr"

    # Create the FroalaEditor instance
    editor = new FroalaEditor selector, options

    return editor 