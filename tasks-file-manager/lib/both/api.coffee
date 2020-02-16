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
  
  _CONVERSION_MATRIX:
      "pdf": [
        "image/jpeg", "image/jpg", 
        "image/png",
        "image/gif", 
        "image/webp",
        "image/heic", "image/heif",
        "image/bmp",
        "image/tiff",
        "application/pdf", , 
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",    # docx
        "application/vnd.openxmlformats-officedocument.presentationml.presentation",  # pptx
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"           # xlsx
      ]
      "jpg": [
        "image/jpeg", "image/jpg", 
        "image/png",
        "image/gif", 
        "image/webp",
        "image/heic", "image/heif",
        "image/bmp",
        "image/tiff",
        "application/pdf", , 
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",    # docx
        "application/vnd.openxmlformats-officedocument.presentationml.presentation",  # pptx
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"           # xlsx
      ]

  getConversionMartix: () ->
    return @_CONVERSION_MATRIX

  isConversionSupported: (src_mime, des_format) ->    
    if (supported_srcs = @_CONVERSION_MATRIX[des_format])?
      return supported_srcs.includes src_mime 
    
    return false