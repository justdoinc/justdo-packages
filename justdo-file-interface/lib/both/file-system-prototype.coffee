_.extend JustdoFileInterface.FileSystemPrototype,
  # 
  # Methods required to register a file system
  # 
  getFileSizeLimit: ->
    # Returns the single file size limit of a file system
    # 
    # Returns: Number, maximum file size for single file upload in bytes
    throw @_error "not-implemented"
  
  getTaskFileLink: (options) ->
    # Returns a URL to download a file
    # Note: The URL returned by this method is for downloading. It should not be used for previewing
    # 
    # Params:
    #   options: Object, required
    #     - task_id: string, required
    #     - file_id: string, required
    # 
    # Returns: String, url to download file. 
    throw @_error "not-implemented"
  
  getFilesByIds: (file_ids) ->
    # Given a single or a list of file_ids, returns an array of normalized file metadata objects 
    # to facilitate usecases like showing a list of files.
    # Note: The returned array will pass through `_ensureFileObjsAreNormalized` to ensure the file metadata objects are normalized
    # 
    # Params:
    #   file_ids: A single file id as string or an array of strings
    # 
    # Returns: Array of Objects with the properties as specified in `_ensureFileObjsAreNormalized`
    throw @_error "not-implemented"
  
  isTaskFileExists: (options) ->
    # Checks if a file exists in a task
    # 
    # Params:
    #   options: Object, required
    #     - task_id: string, required
    #     - file_id: string, required
    # 
    # Returns: Boolean
    throw @_error "not-implemented"
  
  isFileTypePreviewable: (file_type) ->
    # Checks if a file type is previewable
    # 
    # Params:
    #   file_type: string, mime type of file, required
    # 
    # Returns: Boolean
    throw @_error "not-implemented"

  isUserAllowedToUploadTaskFile: (task_id, user_id) ->
    # Checks if a user is allowed to upload a file to a task according to `justdo-permissions`
    # 
    # Params:
    #   task_id: string, required
    #   user_id: string, required
    # 
    # Returns: Boolean
    throw @_error "not-implemented"
  
  # The instance of the file system (e.g. APP.justdo_files, APP.tasks_file_manager_plugin.tasks_file_manager, etc.)
  instance: EventEmitter
