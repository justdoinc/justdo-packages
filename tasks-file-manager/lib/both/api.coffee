_.extend TasksFileManager.prototype,
  _registerCustomChangeTypes: ->
    # Handler for file upload
    APP.tasks_changelog_manager.registerCustomChangeType TasksFileManager.file_upload_change_type,
      getLogMessage: (activity_obj) ->
        performer_name = APP.tasks_changelog_manager.getPerformerNameI18n(activity_obj)
        file_title = activity_obj.data?.file_metadata?.title or ""
        return TAPi18n.__ "file_uploaded_log_message", {performer: performer_name, file_title: file_title}

    # Handler for file rename
    APP.tasks_changelog_manager.registerCustomChangeType TasksFileManager.file_rename_change_type,
      getLogMessage: (activity_obj) ->
        performer_name = APP.tasks_changelog_manager.getPerformerNameI18n(activity_obj)
        old_title = activity_obj.old_value
        new_title = activity_obj.new_value
        return TAPi18n.__ "file_renamed_log_message", {performer: performer_name, old_title: old_title, new_title: new_title}

    # Handler for file remove
    APP.tasks_changelog_manager.registerCustomChangeType TasksFileManager.file_remove_change_type,
      getLogMessage: (activity_obj) ->
        performer_name = APP.tasks_changelog_manager.getPerformerNameI18n(activity_obj)
        file_title = activity_obj.data?.file_metadata?.title
        return TAPi18n.__ "file_removed_log_message", {performer: performer_name, file_title: file_title}
    
    return

  filesForTask: (task_id) -> @tasks_collection.findOne({ _id: task_id }).files

  getShareableLink: (task_id, file_id, root) ->
    project_id = Tracker.nonreactive => @tasks_collection.findOne({_id: task_id})?.project_id

    download_hash = "&hr-id=download-file&hr-file-id=#{encodeURIComponent(file_id)}&hr-task-id=#{encodeURIComponent(task_id)}&hr-project-id=#{encodeURIComponent(project_id)}";
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
        "image/avif",
        "application/photoshop", "application/psd", "application/x-photoshop", "image/photoshop", "image/psd", "image/x-psd", "image/vnd.adobe.photoshop",
        "application/illustrator", "application/postscript",
        "text/plain",
        "text/rtf", "text/richtext", "application/rtf", "application/x-rtf"           # rtf
        "application/pdf",
        "application/msword",                                                         # doc
        "application/vnd.ms-word.document.macroenabled.12"                            # docm
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",    # docx
        "application/vnd.ms-powerpoint",                                              # ppt
        "application/vnd.ms-powerpoint.presentation.marcroenabled.12"                 # pptm
        "application/vnd.openxmlformats-officedocument.presentationml.presentation",  # pptx
        "application/vnd.ms-excel",                                                   # xls
        "application/vnd.ms-excel.sheet.macroenabled.12",                             # xlsm
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"           # xlsx
        "application/vnd.oasis.opendocument.text",                                    # odt
        "application/vnd.oasis.opendocument.presentation",                            # odp
        "application/vnd.oasis.opendocument.spreadsheet",                             # ods
        # The three files are dected as application/zip in filestack for some reason, thus disable conversion support as this point
        # "application/x-iwork-pages-sffpages",                                         # pages
        # "application/x-iwork-keynote-sffkey",                                         # key
        # "application/x-iwork-numbers-sffnumbers"                                      # numbers
      ]
      "jpg": [
        "image/jpeg", "image/jpg", 
        "image/png",
        "image/gif", 
        "image/webp",
        "image/heic", "image/heif",
        "image/bmp",
        "image/tiff",
        "image/avif",
        "application/photoshop", "application/psd", "application/x-photoshop", "image/photoshop", "image/psd", "image/x-psd", "image/vnd.adobe.photoshop",
        "application/illustrator", "application/postscript",
        "text/plain",
        "text/rtf", "text/richtext", "application/rtf", "application/x-rtf"           # rtf
        "application/pdf",
        "application/msword",                                                         # doc
        "application/vnd.ms-word.document.macroenabled.12"                            # docm
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",    # docx
        "application/vnd.ms-powerpoint",                                              # ppt
        "application/vnd.ms-powerpoint.presentation.marcroenabled.12"                 # pptm
        "application/vnd.openxmlformats-officedocument.presentationml.presentation",  # pptx
        "application/vnd.ms-excel",                                                   # xls
        "application/vnd.ms-excel.sheet.macroenabled.12",                             # xlsm
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"           # xlsx
        "application/vnd.oasis.opendocument.text",                                    # odt
        "application/vnd.oasis.opendocument.presentation",                            # odp
        "application/vnd.oasis.opendocument.spreadsheet",                             # ods
        # The three files are dected as application/zip in filestack for some reason, thus disable conversion support as this point
        # "application/x-iwork-pages-sffpages",                                         # pages
        # "application/x-iwork-keynote-sffkey",                                         # key
        # "application/x-iwork-numbers-sffnumbers"                                      # numbers
      ]

  getConversionMartix: () ->
    return @_CONVERSION_MATRIX

  isConversionSupported: (src_mime, des_format) ->    
    if (supported_srcs = @_CONVERSION_MATRIX[des_format])?
      return supported_srcs.includes src_mime 
    
    return false
  
  getFileDownloadPath: (task_id, file_id) ->
    return "#{TasksFileManager.file_download_route}?task_id=#{encodeURIComponent task_id}&file_id=#{encodeURIComponent file_id}"