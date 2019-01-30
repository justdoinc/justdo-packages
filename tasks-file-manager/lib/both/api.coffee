_.extend TasksFileManager.prototype,
  filesForTask: (task_id) -> @tasks_collection.findOne({ _id: task_id }).files

  getShareableLink: (task_id, file_id, root) ->
    download_hash = "&hr-id=download-file&hr-file-id=#{encodeURIComponent(file_id)}&hr-task-id=#{encodeURIComponent(task_id)}";
    if root == "/"
      return  Meteor.absoluteUrl "#" + download_hash

    if window.location.hash
      return window.location + download_hash

    return "#" + download_hash

  getStorageLocationAndPath: (task_id) ->
    location =
      location: "S3"
      path: "/tasks-files/#{task_id}/"

    return location