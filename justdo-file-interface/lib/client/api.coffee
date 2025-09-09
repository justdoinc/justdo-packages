_.extend JustdoFileInterface.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  getFileSizeLimit: ->
    # Returns a number indicating the maximum file size for single file upload in bytes
    # Note: This same limit is will be used for checking file size when calling `APP.justdo_file_interface.uploadBucketFolderFile`
    # before calling the file system's `uploadBucketFolderFile` method to ensure the file size does not exceed the limit.

    fs = @_getFs()

    limit = fs.getFileSizeLimit()

    if _.isString limit
      limit = parseInt limit, 10

    return limit

  isPreviewableCategory: (mime_type) ->
    # Takes mime_type, passes the mime_type to JustdoCoreHelpers.mimeTypeToPreviewCategory to get the previewable category (e.g. image, video, pdf, etc)
    # and passes the category to the file system to determine whether the category is deemed previewable. 
    # Returns true if previewable, false otherwise.
    fs = @_getFs()
    category = JustdoHelpers.mimeTypeToPreviewCategory mime_type
    
    return fs.isPreviewableCategory category

  subscribeToBucketFolder: (bucket_id, folder_name, callbacks) ->
    # IMPORTANT! Before calling any file system methods, you are expected to call this method to load the relevant data.
    #
    # Subscribes to the files collection of the file system. The precise collection and subscription
    # is determined by the file system, and you shouldn't interact directly with the collection (as it is
    # internal to the file system).
    #
    # This is a reactive resource that calls Meteor.subscribe internally.
    # As such, if this method is called inside an autorun, the subscription will be stopped automatically upon invalidation of the autorun.
    #
    # Receives a bucket_id, folder_name and a callbacks object/function, the callbacks object/function is of the exact
    # same format as the callbacks object/function passed to Meteor.subscribe, refer to that API for more details.
    # E.g. to subscribe to the files under a task, call this method with `bucket_id` as "tasks" and `folder_name` as the task_id.
    fs = @_getFs()

    return fs.subscribeToBucketFolder bucket_id, folder_name, callbacks

  getBucketFolderFiles: (bucket_id, folder_name, query, query_options) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Important: This method return file objects with mostly metadata fields. The field names are normalized to be consistent across file systems.
    # This is meant to facilitate usecases like showing a list of files.
    # Since the field names are normalized, it is discouraged to use this method in other file system methods
    fs = @_getFs()

    query = _.extend {}, query
    query_options = _.extend {}, query_options

    return fs.getBucketFolderFiles bucket_id, folder_name, query, query_options
  
  getFileLink: (jd_file_id_obj) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Important: The URL returned by this method is for downloading. It should not be used for previewing
    jd_file_id_obj = @sanitizeJdFileIdObj jd_file_id_obj
    fs = @_getFs(jd_file_id_obj.fs_id)

    return fs.getFileLink jd_file_id_obj
  
  uploadBucketFolderFile: (bucket_id, folder_name, file, cb) ->
    # Gets bucket_id, folder_name and file (the native browser file object) and optionally a cb, uploads the file to the bucket folder.
    #
    # cb will be called with the following params: (err, file_details)
    #   err: Error object if error occurs (e,g, file size exceeds, bucket folder not found or user does not have access, etc). Falsy-value (null/undefined) otherwise.
    #   file_details:
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
      
      file_details = {jd_file_id_obj, additional_details: uploaded_file}

      cb? null, file_details

    return
  
  downloadFile: (jd_file_id_obj) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Gets a jd_file_id_obj, downloads a file from a bucket folder if it is accessible.
    # Note: This method may or may not throw an error if the file does not exist.

    jd_file_id_obj = @sanitizeJdFileIdObj jd_file_id_obj
    fs = @_getFs(jd_file_id_obj.fs_id)

    return fs.downloadFile jd_file_id_obj
  
  isUserAllowedToUploadBucketFolderFile: (bucket_id, folder_name, user_id) ->
    # Gets bucket_id, folder_name and user_id, returns true if a user is allowed to upload a file to a bucket folder, false otherwise
    # 
    # This is NOT called internally by `APP.justdo_file_interface.uploadBucketFolderFile` since it's the file system's responsibility to perform permission checking.
    # A typical usecase for this method is to check whether a user is allowed to upload a file before showing the upload button.
    fs = @_getFs()

    return fs.isUserAllowedToUploadBucketFolderFile bucket_id, folder_name, user_id
  
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
