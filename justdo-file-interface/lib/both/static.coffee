_.extend JustdoFileInterface,
  project_custom_feature_id: "justdo_file_interface" # Use underscores

  plugin_human_readable_name: "justdo-file-interface"

  both_register_fs_options_required_properties:
    uploadFile: Function
    getTaskFileLink: Function
    getFilesByIds: Function
    getFileSizeLimit: Function
    isTaskFileExists: Function
    isFileTypePreviewable: Function
    isUserAllowedToUploadTaskFile: Function
    # Note: Most (if not all) of JustDo plugins are EventEmitter instances, instead of a simple Object.
    instance: EventEmitter
  
  client_register_fs_options_required_properties:
    subscribeToFilesCollection: Function
    downloadFile: Function
    showPreviewOrStartDownload: Function
  
  server_register_fs_options_required_properties: {}