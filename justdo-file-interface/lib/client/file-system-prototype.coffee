_.extend JustdoFileInterface.FileSystemPrototype,
  # 
  # Client-only methods required to register a file system
  # 
  subscribeToBucketFolder: (jd_folder_id_obj, callbacks) ->
    # We require the consumers to call this method before calling other bucket folder methods.
    # When bucket folder and folder's files methods are called - you can assume that the relevant
    # subscription with the same jd_folder_id_obj was called.
    #
    # Receives a jd_folder_id_obj and a callbacks object/function, the callbacks object/function is of the exact
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
    # Interaction example:
    # ```
    # jd_folder_id_obj = {
    #   fs_id: "justdo-files",
    #   bucket_id: "tasks",
    #   folder_name: task_id,
    # }
    # sub_handle = APP.justdo_file_interface.subscribeToBucketFolder(jd_folder_id_obj, {
    #   onReady: () => {
    #     console.log(APP.justdo_file_interface.getBucketFolderFiles(jd_folder_id_obj));
    #     sub_handle.stop();
    #   },
    #   onStop: (err) => {
    #     console.log("Subscription stopped", err);
    #   }
    # });
    # ```

    throw @_error "not-implemented"

  getBucketFolderFiles: (jd_folder_id_obj, query, query_options) ->
    # Consumers are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Gets a jd_folder_id_obj, and optionally query and query_options, 
    # returns an array of the corresponding file metadata objects that belong to the `bucket_id` and `folder_name`.
    # 
    # `query` and `query_options` are in the same format of the ones used in Mongo.
    # It is the file system provider's responsibility to ensure that the `bucket_id` and `folder_name` under `jd_folder_id_obj` 
    # are taking precedence over the `query` and `query_options`.
    # E.g. For "tasks" bucket, the `folder_name` should be used to identify the task, regardless of whether the `query` specifies a different task_id.
    # To facilitate this, the `query` and `query_options` are shallow-cloned before passing them to the file system provider.
    # 
    # "bucket" is a category of files, for example "tasks";
    # "folder_name" is the identifier that allows the file system to find the associated files,
    # for example `task_id` for "tasks" bucket.
    # 
    # Simply put, to get all the files under a task, the consumer would call `getBucketFolderFiles("tasks", task_id)`.
    # 
    # Expected file metadata object structure - it is up to the developer to strictly follow this structure.
    # IMPORTANT: There should be no extra fields in the file metadata object.
    # {
    #   "_id" # file id
    #   "type" # mime type
    #   "name" # filename
    #   "size" # file size in bytes (!)
    #   "uploaded_by" # user id if undefined assume system generated (must be set even if undefined)
    #   "uploaded_at" # js Date object
    # }
    # `is_previewable` will be added to each of the file metadata object by justdo-file-interface,
    # determined by the file system's `isPreviewableCategory` method.

    throw @_error "not-implemented"

  getFileLink: (jd_file_id_obj) ->
    # Consumers are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Gets a jd_file_id_obj, returns a URL to download a file belonging to a bucket folder
    # Note: The URL returned by this method is for downloading. It should not be used for previewing
    throw @_error "not-implemented"
  
  uploadBucketFolderFile: (bucket_id, folder_name, file, cb) ->
    # Gets a File (the native browser file object), bucket_id, folder_name and optionally a cb, uploads the file to the bucket folder.
    #
    # cb will be called with the following params: (err, file_details)
    #   err: Error object if error occurs (e,g, file size exceeds, bucket folder not found or user does not have access, etc). Falsy-value (null/undefined) otherwise.
    #   file_details: An array of objects in the following order, with the following fields:
    #     jd_file_id_obj: The "primary key" of the file. It is recommended to store this object for identifying the file in the future. 
    #                     Refer to the jd_file_id_obj_schema for the exact structure.
    #     additional_details: Additional details of the uploaded file. 
    #                         We return this object despite most of the information can be obtained from browser's File object
    #                         because the file system may normalize/change the name or the size may not be exactly the same as the browser's File object.
    #                         As such, the `additional_details` represents how the file looks like from the file system's perspective.
    #                         Guarenteed to include the following fields:
    #                         {
    #                           _id: String
    #                           name: String # the readable filename of the uploaded file
    #                           type: String # the mime type of the uploaded file
    #                           size: Number # the size of the uploaded file in bytes (!)
    #                         }
    # 
    # We'll ensure that the file size doesn't exceed the file system's `getFileSizeLimit` before trying to upload the file.
    # To be precise: before calling this method inside `APP.justdo_file_interface.uploadBucketFolderFile`, the file size is checked against the
    # file system's `getFileSizeLimit` method to ensure it does not exceed the limit.
    throw @_error "not-implemented"
  
  downloadFile: (jd_file_id_obj) ->
    # Consumers are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Gets a jd_file_id_obj, downloads a file from a bucket folder if it is accessible.
    # Note: This method may or may not throw an error if the file does not exist.
    throw @_error "not-implemented"

  getFileSizeLimit: ->
    # Returns a number indicating the maximum file size for single file upload in bytes
    # Note: This method is called inside `APP.justdo_file_interface.uploadBucketFolderFile`
    # before calling the file system's `uploadBucketFolderFile` method to ensure the file size does not exceed the limit.
    throw @_error "not-implemented"

  isPreviewableCategory: (category) ->
    # Takes category, returns true if a category is deemed previewable by the file system, false otherwise
    # category is one of the returned value from JustdoCoreHelpers.mimeTypeToPreviewCategory
    throw @_error "not-implemented"

  isUserAllowedToUploadBucketFolderFile: (jd_folder_id_obj, user_id) ->
    # Gets jd_folder_id_obj and user_id, returns true if a user is allowed to upload a file to a bucket folder, false otherwise
    # 
    # This is the place to add logic for checking whether user has access to a certain bucket folder before uploading a file to it, 
    # and whether the user is allowed to upload a file to a bucket folder according to `justdo-permissions`
    # 
    # This method is not called automatically inside other methods of file system (e.g. `uploadBucketFolderFile`)
    # A usecase for this method is to check whether a user is allowed to upload a file before showing the upload button.
    throw @_error "not-implemented"

  showFilePreviewOrStartDownload: (jd_file_id_obj, additional_files_ids_in_folder_to_include_in_preview) ->
    # Consumers are expected to call `subscribeToBucketFolder` before calling this method
    #
    # Starts a preview modal of the file if it is previewable by the file system, otherwise downloads the file directly.
    # The preview modal is up to you to implement.
    #
    # The preview should include all the previewable files under the same `bucket_id` and `folder_name`, unless
    # limited by the `additional_files_ids_in_folder_to_include_in_preview` param.
    #
    # If `additional_files_ids_in_folder_to_include_in_preview` is provided, it is expected to be an array of file ids.
    # if empty array - show only the file requested in the preview.
    # if undefined - show all the previewable files under the same `bucket_id` and `folder_name`.
    # otherwise - show the files in the `additional_files_ids_in_folder_to_include_in_preview` array.

    throw @_error "not-implemented"

  getFilePreviewLinkAsync: (jd_file_id_obj) ->
    # Consumers are expected to call `subscribeToBucketFolder` before calling this method
    #
    # Gets a jd_file_id_obj, returns a promise that resolves to a URL to preview a file belonging to a bucket folder
    # Note: The URL returned by this method is for previewing. It should not be used for downloading.

    throw @_error "not-implemented"