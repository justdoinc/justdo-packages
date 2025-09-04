_.extend JustdoFileInterface.FileSystemPrototype,
  # 
  # Client-only methods required to register a file system
  # 
  uploadTaskFile: (file, task_id, cb) ->
    # Uploads a file to a task
    # 
    # Params:
    #   file: File object, required
    #   task_id: String, required
    #   cb: Function (err, uploaded_file), optional
    #     - err: Error object if error occurs, falsy-value otherwise
    #     - uploaded_file: File metadata object, guarenteed to have the following properties:
    #         - _id: String
    #         - name: String
    #         - type: String
    #         - size: Number
    #         - (extra properties returned by the file system)
    throw @_error "not-implemented"
  
  subscribeToTaskFilesCollection: (task_id, cb) ->
    # Subscribes to file system's task files collection. 
    # 
    # Params:
    #   task_id: String, required
    # 
    #   cb: Function, optional
    #     cb is guarenteed to be called only once in the following way:
    #       - `onStop` callback of the subscription with `err` as param IF the subscription is stopped before becoming ready
    #       - `onReady` callback of the subscription with no param IF the subscription is ready
    #     This is to provide a mechanism for the caller to know when the subscription is ready or if it failed.
    # 
    # Returns: Meteor subscription handle
    throw @_error "not-implemented"
  
  downloadTaskFile: (options) ->
    # Downloads a file from a task
    # 
    # Params:
    #   options: Object, required
    #     - task_id: String, required
    #     - file_id: String, required
    # 
    # Returns: (undefined)
    throw @_error "not-implemented"
  
  showTaskFilePreviewOrStartDownload: (task_id, file, file_ids_to_show) ->
    # If provided `file` deemed previewable by the file system, show the preview modal with the `file`; Otherwise, download the file directly.
    # The preview modal allows user to show all other previewable files under the same `task_id`;
    # If `file_ids_to_show` is provided, only the files under the same `tsak_id` AND in the `file_ids_to_show` array will be accessible in the preview modal.
    # A sample usecase of the `file_ids_to_show` param is to show only files attached to a single chat message, instead of all the files under a task.
    # 
    # Params:
    #   task_id: String, required
    #   file: String or Object, required
    #     If string, it is assumed to be the `file_id` of the file.
    #     If object, it is assumed to be the metadata of the file with the following properties:
    #       - _id: String, required
    #       - type: String, required
    #       - name: String, required
    #   file_ids_to_show: Array of file_ids, optional
    # 
    # Returns: (undefined)
    throw @_error "not-implemented"