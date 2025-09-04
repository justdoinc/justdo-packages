_.extend JustdoFileInterface.FileSystemPrototype,
  # 
  # The following methods are required to register a file system:
  #
  # IMPORTANT THERE ARE MORE REQUIRED METHODS TO BE IMPLEMENTED IN the /client/ /server/ folders.
  # 
  getFileSizeLimit: ->
    # Returns a number indicating the maximum file size for single file upload in bytes
    throw @_error "not-implemented"
  
  getTaskFileLink: (file_id, task_id) ->
    # Gets file_id and task_id, returns a URL to download a file belonging to a task
    # Note: The URL returned by this method is for downloading. It should not be used for previewing
    throw @_error "not-implemented"

  getTaskFilesByIds: (file_ids, task_id) ->
    # Gets an array of file_ids and a task_id, returns an array of the corresponding file metadata objects that belong to the `task_id`.
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
    # Gets file_id and task_id, returns true if the file exists in the task, false otherwise
    throw @_error "not-implemented"
  
  isFileTypePreviewable: (file_type) ->
    # Gets file_type, returns true if a file type is deemed previewable by the file system, false otherwise
    throw @_error "not-implemented"

  isUserAllowedToUploadTaskFile: (task_id, user_id) ->
    # Gets task_id and user_id, returns true if a user is allowed to upload a file to a task, false otherwise
    # 
    # This is the place to add logic for checking whether user has access to a certain task before uploading a file to it, 
    # and whether the user is allowed to upload a file to a task according to `justdo-permissions`
    # 
    # This method is not called automatically inside other methods of file system (e.g. `uploadTaskFile`)
    # A usecase for this method is to check whether a user is allowed to upload a file before showing the upload button.
    throw @_error "not-implemented"
  