_.extend JustdoFileInterface.FileSystemPrototype,
  # 
  # Client-only methods required to register a file system
  # 

  #
  # Upload related methods
  #
  getFileSizeLimit: ->
    # Returns a number indicating the maximum file size for single file upload in bytes
    # Note: This method is called inside `APP.justdo_file_interface.uploadBucketFolderFile`
    # before calling the file system's `uploadBucketFolderFile` method to ensure the file size does not exceed the limit.
    throw @_error "not-implemented"

  isUserAllowedToUploadBucketFolderFile: (bucket_id, folder_name, user_id) ->
    # Gets bucket_id, folder_name and user_id, returns true if a user is allowed to upload a file to a bucket folder, false otherwise
    # 
    # This is the place to add logic for checking whether user has access to a certain bucket folder before uploading a file to it, 
    # and whether the user is allowed to upload a file to a bucket folder according to `justdo-permissions`
    # 
    # This method is not called automatically inside other methods of file system (e.g. `uploadBucketFolderFile`)
    # A usecase for this method is to check whether a user is allowed to upload a file before showing the upload button.
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
  
  #
  # Consumption related methods
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

  getBucketFolderFiles: (jd_folder_id_obj, file_ids) ->
    # Consumers are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Gets a jd_folder_id_obj returns an array of the corresponding file metadata objects
    # that belong to the `bucket_id` and `folder_name` of `jd_folder_id_obj`.
    #
    # file_ids is optional, if provided, it is expected to be an array of file ids (you don't need to implement the case of string file_id).
    # If provided, the method will limit the returned object only for the files in the folder with the corresponding file ids.
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

    throw @_error "not-implemented"

  getFileLink: (jd_file_id_obj) ->
    # Consumers are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Gets a jd_file_id_obj, returns a URL to download a file belonging to a bucket folder
    # Note: The URL returned by this method is for downloading. It should not be used for previewing
    throw @_error "not-implemented"
  
  downloadFile: (jd_file_id_obj, cb) ->
    # Consumers are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Gets a jd_file_id_obj, downloads a file from a bucket folder if it is accessible.
    #
    # cb is optional, will be called with the following params: (err)
    #   err: Error object if error occurs undefined otherwise.
    throw @_error "not-implemented"

  isPreviewableCategory: (category) ->
    # Takes category, returns true if a category is deemed previewable by the file system, false otherwise
    # category is one of the returned value from JustdoCoreHelpers.mimeTypeToPreviewCategory
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

  getFilePreviewLink: (jd_file_id_obj, cb) ->
    # Consumers are expected to call `subscribeToBucketFolder` before calling this method
    #
    # Gets a jd_file_id_obj, returns a promise that resolves to a URL to preview a file belonging to a bucket folder
    # Note: The URL returned by this method is for previewing. It should not be used for downloading.

    throw @_error "not-implemented"