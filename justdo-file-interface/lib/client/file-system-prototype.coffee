_.extend JustdoFileInterface.FileSystemPrototype,
  # 
  # Client-only methods required to register a file system
  # 
  subscribeToBucketFolder: (bucket_id, folder_name, callbacks) ->
    # We require the consumers to call this method before calling other bucket folder methods.
    # When bucket folder and folder's files methods are called - you can assume that the relevant
    # subscription with the same bucket_id and folder_name was called.
    #
    # Receives a bucket_id and a folder_name and a callbacks object/function, the callbacks object/function is of the exact
    # same format as the callbacks object/function passed to Meteor.subscribe, refer to that API for more details.
    #
    # This is a reactive resource that calls Meteor.subscribe internally.
    # As such, if this method is called inside an autorun, the subscription will be stopped automatically upon invalidation of the autorun.
    # 
    # The consumers are expected to interact with your file systems using the justdo file interface apis, without the need
    # of understanding or interacting with the underlying collection/s. You can assume that the consumer will not interact
    # with the underlying collection/s that receives the subscription data. As such, this method is meant to allow you to
    # prepare the necessary data before the consumer interacts with the bucket folder and folder's files.
    #
    # XXX the following should be copy-pastable to the browser console - and work.
    # Interaction example:
    # ```
    # sub_handle = APP.justdo_file_interface.subscribeToBucketFolder("tasks", "task_id", {
    #   onReady: ->
    #     console.log(APP.justdo_file_interface.getBucketFolderFiles())
    #     sub_handle.stop()
    #   onStop: (err) ->
    #     console.log("Subscription stopped", err)
    # })
    # ```

    throw @_error "not-implemented"

  getBucketFolderFiles: (bucket_id, folder_name) ->
    # Gets a bucket_id and a folder_name, returns an array of file objects under it.
    # "bucket" is a category of files, for example "tasks";
    # "folder_name" is the identifier that allows the file system to find the associated files,
    # for example `task_id` for "tasks" bucket.
    # Simply put, to get all the files under a task, the consumer would call `getBucketFolderFiles("tasks", task_id)`.
    throw @_error "not-implemented"

_.extend JustdoFileInterface.FileSystemApis,
  # 
  # Client-only file system methods implemented by justd-file-interface
  # 
  subscribeToTaskFiles: (task_id, callbacks) ->
    @subscribeToBucketFolder "tasks", task_id, callbacks

  getTaskFiles: (task_id) ->
    @getBucketFolderFiles "tasks", task_id

  getFileSizeLimit: ->
    # Returns a number indicating the maximum file size for single file upload in bytes
    # Note: This method is called inside `APP.justdo_file_interface.uploadTaskFile`
    # before calling the file system's `uploadTaskFile` method to ensure the file size does not exceed the limit.
    throw @_error "not-implemented"
  
  getTaskFileLink: (file_id, task_id) ->
    # Consumers are expected to call `subscribeToTaskFiles` before calling this method
    # 
    # Gets file_id and task_id, returns a URL to download a file belonging to a task
    # Note: The URL returned by this method is for downloading. It should not be used for previewing
    throw @_error "not-implemented"

  getTaskFilesByIds: (task_id, file_ids) ->
    # Consumers are expected to call `subscribeToTaskFiles` before calling this method
    # 
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
    #   "size" # file size in bytes (!)
    #   "uploaded_by" # user id if undefined assume system generated (must be set even if undefined)
    #   "uploaded_at" # js Date object
    # }
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

  uploadTaskFile: (file, task_id, cb) ->
    # Gets a File (the native browser file object), task_id and optionally a cb, uploads the file to the task.
    #
    # cb will be called with the following params: (err, uploaded_file)
    #   err: Error object if error occurs (e,g, file size exceeds, task not found or user does not have access, etc). Falsy-value (null/undefined) otherwise.
    #   uploaded_file:
    #     {
    #       _id: String
    #       name: String # the readable filename of the uploaded file
    #       type: String # the mime type of the uploaded file
    #       size: Number # the size of the uploaded file in bytes (!)
    #     }
    #   It is up to the developer to strictly follow this structure.
    #   IMPORTANT: There should be no extra fields in the uploaded_file object.
    # 
    # We'll ensure that the file size doesn't exceed the file system's `getFileSizeLimit` before trying to upload the file.
    # To be precise: before calling this method inside `APP.justdo_file_interface.uploadTaskFile`, the file size is checked against the
    # file system's `getFileSizeLimit` method to ensure it does not exceed the limit.
    throw @_error "not-implemented"
  
  downloadTaskFile: (file_id, task_id) ->
    # Consumers are expected to call `subscribeToTaskFiles` before calling this method
    # 
    # Gets a file_id and task_id, downloads a file from a task if it is accessible.
    # Note: This method may or may not throw an error if the file does not exist.
    throw @_error "not-implemented"
  
  showTaskFilePreviewOrStartDownload: (file, task_id, file_ids_to_show) ->
    # Consumers are expected to call `subscribeToTaskFiles` before calling this method
    # 
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