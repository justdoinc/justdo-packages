_.extend JustdoFileInterface.prototype,
  subscribeToTaskFiles: (task_id, callbacks) ->
    # IMPORTANT! Before calling any tasks methods, you are expected to call this method to load the relevant data.
    #
    # Subscribes to the task files collection of the file system. The precise collection and subscription
    # is determined by the file system, and you shouldn't interact directly with the collection (as it is
    # internal to the file system).
    #
    # This is a reactive resource that calls Meteor.subscribe internally.
    # As such, if this method is called inside an autorun, the subscription will be stopped automatically upon invalidation of the autorun.
    #
    # Receives a task_id and a callbacks object/function, the callbacks object/function is of the exact
    # same format as the callbacks object/function passed to Meteor.subscribe, refer to that API for more details.
    #
    # You are expected to call this method to load the relevant data
    # before calling query-involved methods like `getTaskFileLink`, `getTaskFilesByIds`, `downloadTaskFile`, `showTaskFilePreviewOrStartDownload` and alike.

    return @subscribeToBucketFolder "tasks", task_id, callbacks

  getTaskFileLink: (task_id, file_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    # 
    # Important: The URL returned by this method is for downloading. It should not be used for previewing

    return @getBucketFolderFileLink "tasks", task_id, file_id
  
  getTaskFiles: (task_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    return @getBucketFolderFiles "tasks", task_id

  getTaskFilesByIds: (task_id, file_ids) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    # 
    # Important: This method return file objects with mostly metadata fields. The field names are normalized to be consistent across file systems.
    # This is meant to facilitate usecases like showing a list of files.
    # Since the field names are normalized, it is discouraged to use this method in other file system methods

    if _.isString file_ids
      file_ids = [file_ids]

    return @getBucketFolderFiles "tasks", task_id, {_id: {$in: file_ids}}

  isUserAllowedToUploadTaskFile: (task_id, user_id) ->
    return @isUserAllowedToUploadBucketFolderFile "tasks", task_id, user_id

  uploadTaskFile: (task_id, file, cb) ->
    @uploadBucketFolderFile "tasks", task_id, file, cb
    return
  
  downloadTaskFile: (task_id, file_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method

    return @downloadBucketFolderFile "tasks", task_id, file_id

  showTaskFilePreviewOrStartDownload: (task_id, file, file_ids_to_show) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    return @showBucketFolderFilePreviewOrStartDownload "tasks", task_id, file, file_ids_to_show
  
  getTaskFilePreviewLinkAsync: (task_id, file_id) ->
    # Important: You are expected to call `subscribeToTaskFiles` before calling this method
    return @getBucketFolderFilePreviewLinkAsync "tasks", task_id, file_id