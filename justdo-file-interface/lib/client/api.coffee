_.extend JustdoFileInterface.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  #
  # Upload related methods
  #
  
  # Note how for all of these methods we don't take the jd_file_id_obj as param.
  # The jd_file_id_obj/jd_folder_id_obj are a mean to address existing files/folders.
  # For uploading new files/folders, the expectation is that the current default file
  # system is used, and further, that's the behavior we want to encourage - hence we
  # only require the `bucket_id` and `folder_name` for uploading new files, and we don't
  # ask for the fs explicitly.
  #
  # If you do want to upload to an alternative file system, you can always call the @cloneWithForcedFs(fs_id)
  # (see documentation there).
  getFileSizeLimit: ->
    # Returns a number indicating the maximum file size for a single file upload in bytes.
    #
    # Notes:
    # 1. This same limit is will be used for checking file size when calling `APP.justdo_file_interface.uploadBucketFolderFile`
    # before calling the file system's `uploadBucketFolderFile` method to ensure the file size does not exceed the limit.
    # 2. See comment above for why this method doesn't take fs_id as param.

    fs = @_getFs()

    limit = fs.getFileSizeLimit()

    if _.isString limit
      limit = parseInt limit, 10

    return limit

  uploadBucketFolderFile: (bucket_id, folder_name, file, cb) ->
    # Gets bucket_id, folder_name and file (the native browser file object) and optionally a cb, uploads the file to the bucket folder.
    #
    # cb will be called with the following params: (err, file_details)
    #   err: Error object if error occurs undefined otherwise.
    #        Errors can be general, such as file size exceeded. But you can also expect bucket-specific errors such as:
    #         - bucket folder not found (can happen in scenarios like tasks upload, if the task id, represented by the folder_name doesn't exist)
    #         - user does not have access (again, in the case of tasks upload, if the user doesn't have access to the task)
    #        etc.
    #
    #   file_details: An *array* of objects [jd_file_id_obj, additional_details] in the following order, with the following fields:
    #     jd_file_id_obj: The "primary key" of the file. You should store this object to indentify and operate on the file in the future. 
    #                     Refer to the jd_file_id_obj_schema (in schemas.coffee) for the exact structure.
    #     additional_details: Additional details of the uploaded file. 
    #                         We return this object despite most of the information can be obtained from the browser's File object (even prior to the upload)
    #                         because the file system may: normalize/change the name, or the size may not be exactly the same as the browser's File object (due to file system specific reasons).
    #                         As such, the `additional_details` represents how the file looks like from the file system's perspective.
    #                         Guarenteed to include the following fields only (regardless of the current file system):
    #                         {
    #                           _id: String
    #                           name: String # the readable filename of the uploaded file
    #                           type: String # the mime type of the uploaded file
    #                           size: Number # the size of the uploaded file in bytes (!)
    #                         }
    #
    # See comment above for why this method doesn't take fs_id as param.

    fs = @_getFs()

    file_size_limit = @getFileSizeLimit fs.fs_id
    if file_size_limit? and file.size > file_size_limit
      cb? @_error "file-size-exceeded", "File size exceeds the #{JustdoHelpers.bytesToHumanReadable file_size_limit} limit of file system #{fs.fs_id}"
      return

    fs.uploadBucketFolderFile bucket_id, folder_name, file, (err, uploaded_file) ->
      if err?
        cb? err
        return

      jd_file_id_obj = 
        fs_id: fs.fs_id
        bucket_id: bucket_id
        folder_name: folder_name
        file_id: uploaded_file._id
      
      file_details = [jd_file_id_obj, uploaded_file]

      cb? undefined, file_details

    return
  
  isUserAllowedToUploadBucketFolderFile: (jd_folder_id_obj, user_id) ->
    # Gets bucket_id, folder_name and user_id, returns true if a user is allowed to upload a file to a bucket folder, false otherwise
    # 
    # This is NOT called internally by `APP.justdo_file_interface.uploadBucketFolderFile` since it's the file system's responsibility to perform permission checking.
    # A typical usecase for this method is to check whether a user is allowed to upload a file before showing the upload button.
    jd_folder_id_obj = @sanitizeJdFolderIdObj jd_folder_id_obj
    fs = @_getFs(jd_folder_id_obj.fs_id)

    return fs.isUserAllowedToUploadBucketFolderFile jd_folder_id_obj, user_id
  
  #
  # Consumption related methods
  #
  subscribeToBucketFolder: (jd_folder_id_obj, callbacks) ->
    # IMPORTANT! Before calling any file system methods, you are expected to call this method to load the relevant data.
    #
    # Subscribes to the files collection of the file system. The precise collection and subscription
    # is determined by the file system, and you shouldn't interact directly with the collection (as it is
    # internal to the file system).
    #
    # This is a reactive resource that calls Meteor.subscribe internally.
    # As such, if this method is called inside an autorun, the subscription will be stopped automatically upon invalidation of the autorun.
    #
    # Receives a jd_folder_id_obj and a callbacks object/function, the callbacks object/function is of the exact
    # same format as the callbacks object/function passed to Meteor.subscribe, refer to that API for more details.
    # E.g. to subscribe to the files under a task, call this method with `jd_folder_id_obj` as `{fs_id: "justdo-files", bucket_id: "tasks", folder_name: task_id}`.
    jd_folder_id_obj = @sanitizeJdFolderIdObj jd_folder_id_obj
    fs = @_getFs(jd_folder_id_obj.fs_id)

    return fs.subscribeToBucketFolder jd_folder_id_obj, callbacks

  getBucketFolderFiles: (jd_folder_id_obj, query, query_options) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # This method return file objects with mostly metadata fields. The field names are normalized to be consistent across file systems.
    # For the returned file objects' structure, check the comment in the `getBucketFolderFiles` method in /client/file-system-prototype.coffee.
    # This is meant to facilitate usecases like showing a list of files.
    # Since the field names are normalized, it is discouraged to use this method in other file system methods
    jd_folder_id_obj = @sanitizeJdFolderIdObj jd_folder_id_obj
    fs = @_getFs(jd_folder_id_obj.fs_id)

    query = _.extend {}, query
    query_options = _.extend {}, query_options

    files = _.map fs.getBucketFolderFiles(jd_folder_id_obj, query, query_options), (file) ->
      category = JustdoHelpers.mimeTypeToPreviewCategory file.type
      file.is_previewable = fs.isPreviewableCategory category
      return file
    
    return files
  
  getFileLink: (jd_file_id_obj) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Important: The URL returned by this method is for downloading. It should not be used for previewing
    jd_file_id_obj = @sanitizeJdFileIdObj jd_file_id_obj
    fs = @_getFs(jd_file_id_obj.fs_id)

    return fs.getFileLink jd_file_id_obj
  
  downloadFile: (jd_file_id_obj) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Gets a jd_file_id_obj, downloads a file from a bucket folder if it is accessible.
    # Note: This method may or may not throw an error if the file does not exist.

    jd_file_id_obj = @sanitizeJdFileIdObj jd_file_id_obj
    fs = @_getFs(jd_file_id_obj.fs_id)

    return fs.downloadFile jd_file_id_obj
  
  showFilePreviewOrStartDownload: (jd_file_id_obj, additional_files_ids_in_folder_to_include_in_preview) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Starts a preview modal of the file if it is previewable by the file system, otherwise downloads the file directly.
    # The preview includes all the previewable files under the same `bucket_id` and `folder_name`, unless
    # limited by the `additional_files_ids_in_folder_to_include_in_preview` param.
    #
    # If `additional_files_ids_in_folder_to_include_in_preview` is provided, it is expected to be an array of file ids.
    # if empty array - show only the file requested in the preview.
    # if undefined - show all the previewable files under the same `bucket_id` and `folder_name`.
    # otherwise - show the files in the `additional_files_ids_in_folder_to_include_in_preview` array.

    jd_file_id_obj = @sanitizeJdFileIdObj jd_file_id_obj
    fs = @_getFs(jd_file_id_obj.fs_id)

    return fs.showFilePreviewOrStartDownload jd_file_id_obj, additional_files_ids_in_folder_to_include_in_preview

  getFilePreviewLinkAsync: (jd_file_id_obj) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
    #
    # Gets a jd_file_id_obj, returns a promise that resolves to a URL to preview a file belonging to a bucket folder
    # Note: The URL returned by this method is for previewing. It should not be used for downloading.

    jd_file_id_obj = @sanitizeJdFileIdObj jd_file_id_obj
    fs = @_getFs(jd_file_id_obj.fs_id)

    promise = new Promise (resolve, reject) ->
      fs.getFilePreviewLinkAsync jd_file_id_obj, (err, preview_link) ->
        if err?
          reject err
        else
          resolve(preview_link)
        return
    
    return promise
