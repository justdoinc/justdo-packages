_.extend JustdoFileInterface.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  getFileSizeLimit: (fs_id) ->
    fs = @_getFs()

    limit = fs.getFileSizeLimit()

    if _.isString limit
      limit = parseInt limit, 10

    return limit

  isPreviewableCategory: (mime_type) ->
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
    jd_file_id_obj = @sanitizeJdFileIdObj jd_file_id_obj
    fs = @_getFs(jd_file_id_obj.fs_id)

    return fs.downloadFile jd_file_id_obj
  
  isUserAllowedToUploadBucketFolderFile: (bucket_id, folder_name, user_id) ->
    fs = @_getFs()

    return fs.isUserAllowedToUploadBucketFolderFile bucket_id, folder_name, user_id
  
  showFilePreviewOrStartDownload: (jd_file_id_obj, additional_files_ids_in_folder_to_include_in_preview) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
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
