_.extend JustdoFileInterface.FileSystemPrototype,
  # 
  # Client-only methods required to register a file system
  # 
  uploadTaskFile: (file, task_id, cb) ->
    # Gets a file, task_id and optionally a cb, uploads a file to a task
    # cb will be called with the following params: (err, uploaded_file)
    #   err: Error object if error occurs (e,g, file size exceeds, task not found or user does not have access, etc). Falsy-value otherwise
    #   uploaded_file: File metadata object, guarenteed to have the following properties:
    #     {
    #       _id: String
    #       name: String
    #       type: String
    #       size: Number
    #       ...(any extra properties returned by the file system)
    #     }
    throw @_error "not-implemented"
  
  subscribeToTaskFilesCollection: (task_id, cb) ->
    # Gets a task_id and optionally a cb, subscribes to file system's task files collection and returns the subscription handle
    # Note: There's no guarentee that the subscription will be stopped with an error if the task does not exist or the user does not have access to the task.
    # cb is guarenteed to be called only once in the following way:
    #   - `onStop` callback of the subscription with `err` as the first param IF the subscription is stopped before becoming ready
    #   - `onReady` callback of the subscription without param IF the subscription is ready
    # This is to provide a mechanism for the caller to know when the subscription is ready or if it failed.
    throw @_error "not-implemented"
  
  downloadTaskFile: (file_id, task_id) ->
    # Gets a file_id and task_id, downloads a file from a task if it is accessible.
    # Note: This method may or may not throw an error if the file does not exist.
    throw @_error "not-implemented"
  
  showTaskFilePreviewOrStartDownload: (file, task_id, file_ids_to_show) ->
    # Gets a file, task_id and optionally an array of file_ids_to_show.
    # `file` can be a string or an object with the following properties:
    # {
    #   _id: String
    #   type: String
    #   name: String
    # }
    # If provided `file` deemed previewable by the file system, show the preview modal with the `file`; Otherwise, download the file directly.
    # The preview modal allows user to show all other previewable files under the same `task_id`;
    # If `file_ids_to_show` is provided, only the files under `task_id` specified in the `file_ids_to_show` array will be shown in the preview modal.
    # A sample usecase of the `file_ids_to_show` param is to show only files attached to a single chat message, instead of all the files under a task.
    throw @_error "not-implemented"