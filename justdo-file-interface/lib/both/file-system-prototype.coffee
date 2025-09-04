_.extend JustdoFileInterface.FileSystemPrototype,
  # 
  # The following methods are required to register a file system:
  #
  # IMPORTANT THERE ARE MORE REQUIRED METHODS TO BE IMPLEMENTED IN the /client/ /server/ folders.
  # 
  getFileSizeLimit: ->
    # Returns the single file size limit of a file system
    # 
    # Returns: Number, maximum file size for single file upload in bytes
    throw @_error "not-implemented"
  
  getTaskFileLink: (file_id, task_id) ->
    # Returns a URL to download a file belonging to a task
    # Note: The URL returned by this method is for downloading. It should not be used for previewing
    # 
    # Params:
    #   file_id: string, required
    #   task_id: string, required
    # 
    # Returns: String, url to download file. 
    throw @_error "not-implemented"

  getTaskFilesByIds: (file_ids, task_id) ->
    # Gets an array of file_ids, returns an array of the corresponding file metadata objects that belong to a task.
    #
    # The returned array order won't necessarily be the same as the order of the file_ids.
    # Further, if some of the file_ids don't exist, or permission are denied, the returned array
    # won't contain the corresponding file metadata objects.
    #
    # E.g if file_ids is [file_id_1, file_id_2, file_id_3], and non of them exist, the returned
    # array will be empty.
    #
    # Expexted file metadata object structure - it is up to the developer to strictly follow this structure.
    # IMPORTANT: There should be no extra fields in the file metadata object.
    # {
    #   "_id" # file id
    #   "type" # mime type
    #   "name" # filename
    #   "size" # file size in bytes
    #   "uploaded_by" # user id if undefined assume system generated (must be set even if undefined)
    #   "uploaded_at" # js Date object
    # }
    throw @_error "not-implemented"
  
  isTaskFileExists: (file_id, task_id) ->
    # Checks if a file exists in a task
    # 
    # Params:
    #   file_id: string, required
    #   task_id: string, required
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
