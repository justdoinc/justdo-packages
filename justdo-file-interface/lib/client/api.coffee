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
  
  getBucketFolderFileLink: (jd_file_id_obj) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
    # 
    # Important: The URL returned by this method is for downloading. It should not be used for previewing
    jd_file_id_obj = @sanitizeJdFileIdObj jd_file_id_obj
    fs = @_getFs(jd_file_id_obj.fs_id)

    return fs.getBucketFolderFileLink jd_file_id_obj
  
  uploadBucketFolderFile: (bucket_id, folder_name, file, cb) ->
    fs = @_getFs()

    file_size_limit = @getFileSizeLimit fs.fs_id
    if file_size_limit? and file.size > file_size_limit
      cb @_error "file-size-exceeded", "File size exceeds the #{JustdoHelpers.bytesToHumanReadable file_size_limit} limit of file system #{fs.fs_id}"
      return

    fs.uploadBucketFolderFile bucket_id, folder_name, file, cb

    return
  
  downloadBucketFolderFile: (jd_file_id_obj) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
    jd_file_id_obj = @sanitizeJdFileIdObj jd_file_id_obj
    fs = @_getFs(jd_file_id_obj.fs_id)

    return fs.downloadBucketFolderFile jd_file_id_obj
  
  isUserAllowedToUploadBucketFolderFile: (bucket_id, folder_name, user_id) ->
    fs = @_getFs()

    return fs.isUserAllowedToUploadBucketFolderFile bucket_id, folder_name, user_id
  
  showFilePreviewOrStartDownload: (jd_file_id_obj, additional_files_ids_in_folder_to_include_in_preview) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
    jd_file_id_obj = @sanitizeJdFileIdObj jd_file_id_obj
    fs = @_getFs(jd_file_id_obj.fs_id)

    return fs.showFilePreviewOrStartDownload jd_file_id_obj, additional_files_ids_in_folder_to_include_in_preview

  getBucketFolderFilePreviewLinkAsync: (jd_file_id_obj) ->
    # Important: You are expected to call `subscribeToBucketFolder` before calling this method
    #
    # Gets a jd_file_id_obj, returns a promise that resolves to a URL to preview a file belonging to a bucket folder
    # Note: The URL returned by this method is for previewing. It should not be used for downloading.

    jd_file_id_obj = @sanitizeJdFileIdObj jd_file_id_obj
    fs = @_getFs(jd_file_id_obj.fs_id)

    promise = new Promise (resolve, reject) ->
      fs.getBucketFolderFilePreviewLinkAsync jd_file_id_obj, (err, preview_link) ->
        if err?
          reject err
        else
          resolve(preview_link)
        return
    
    return promise
