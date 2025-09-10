_.extend JustdoFileInterface.prototype,
  subscribeToTaskFiles: (fs_id, task_id, callbacks) ->
    # IMPORTANT! Before calling any tasks methods, you are expected to call this method to load the relevant data.
    #
    # Subscribes to the task files collection of the file system. The precise collection and subscription
    # is determined by the file system, and you shouldn't interact directly with the collection (as it is
    # internal to the file system).
    #
    # This is a reactive resource that calls Meteor.subscribe internally.
    # As such, if this method is called inside an autorun, the subscription will be stopped automatically upon invalidation of the autorun.
    #
    # Receives a fs_id, a task_id and a callbacks object/function, the callbacks object/function is of the exact
    # same format as the callbacks object/function passed to Meteor.subscribe, refer to that API for more details.
    #
    # You are expected to call this method to load the relevant data
    # before calling query-involved methods like `getTaskFileLink`, `getTaskFilesByIds`, `downloadTaskFile`, `showTaskFilePreviewOrStartDownload` and alike.

    jd_folder_id_obj = 
      fs_id: fs_id
      bucket_id: "tasks"
      folder_name: task_id

    return @subscribeToBucketFolder jd_folder_id_obj, callbacks

  getTaskFileLink: (fs_id, task_id, file_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    # 
    # Important: The URL returned by this method is for downloading. It should not be used for previewing
    
    jd_file_id_obj = 
      fs_id: fs_id
      bucket_id: "tasks"
      folder_name: task_id
      file_id: file_id

    return @getFileLink jd_file_id_obj
  
  getTaskFiles: (fs_id, task_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    jd_folder_id_obj = 
      fs_id: fs_id
      bucket_id: "tasks"
      folder_name: task_id

    return @getBucketFolderFiles jd_folder_id_obj

  getTaskFilesByIds: (fs_id, task_id, file_ids) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    # 
    # Important: This method return file objects with mostly metadata fields. The field names are normalized to be consistent across file systems.
    # This is meant to facilitate usecases like showing a list of files.
    # Since the field names are normalized, it is discouraged to use this method in other file system methods

    jd_folder_id_obj = 
      fs_id: fs_id
      bucket_id: "tasks"
      folder_name: task_id

    if _.isString file_ids
      file_ids = [file_ids]

    return @getBucketFolderFiles jd_folder_id_obj, {_id: {$in: file_ids}}

  isUserAllowedToUploadTaskFile: (fs_id, task_id, user_id) ->
    jd_folder_id_obj = 
      fs_id: fs_id
      bucket_id: "tasks"
      folder_name: task_id

    return @isUserAllowedToUploadBucketFolderFile jd_folder_id_obj, user_id

  uploadTaskFile: (task_id, file, cb) ->
    # Refer to the documentation of `uploadBucketFolderFile` for the parameters of the `cb`
    @uploadBucketFolderFile "tasks", task_id, file, cb
    return
  
  downloadTaskFile: (fs_id, task_id, file_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    # 
    # Gets a jd_file_id_obj, downloads a file from the `task_id` if the file and task are both accessible.
    # Note: This method may or may not throw an error if the file does not exist.

    jd_file_id_obj = 
      fs_id: fs_id
      bucket_id: "tasks"
      folder_name: task_id
      file_id: file_id

    return @downloadFile jd_file_id_obj

  showTaskFilePreviewOrStartDownload: (fs_id, task_id, file_id, file_ids_to_show) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    jd_file_id_obj = 
      fs_id: fs_id
      bucket_id: "tasks"
      folder_name: task_id
      file_id: file_id

    return @showFilePreviewOrStartDownload jd_file_id_obj, file_ids_to_show
  
  getTaskFilePreviewLinkAsync: (fs_id, task_id, file_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    #
    # Gets a task_id and file_id, returns a promise that resolves to a URL to preview a file belonging to a bucket folder
    # Note: The URL returned by this method is for previewing. It should not be used for downloading.

    jd_file_id_obj = 
      fs_id: fs_id
      bucket_id: "tasks"
      folder_name: task_id
      file_id: file_id

    return @getFilePreviewLinkAsync jd_file_id_obj