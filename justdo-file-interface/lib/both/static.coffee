_.extend JustdoFilesInterface,
  project_custom_feature_id: "justdo_file_interface" # Use underscores

  plugin_human_readable_name: "justdo-file-interface"

  both_register_fs_options_required_properties:
    uploadFile: Function
    getFileLink: Function
    getFilesByIds: Function
    getFileSizeLimit: Function
    isFileExists: Function
    isFileTypePreviewable: Function
    # Note: Most (if not all) of JustDo plugins are EventEmitter instances, instead of a simple Object.
    instance: EventEmitter
  
  client_register_fs_options_required_properties:
    subscribeToFilesCollection: Function
    downloadFile: Function
  
  server_register_fs_options_required_properties: {}