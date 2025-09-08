_.extend JustdoFiles,
  project_custom_feature_id: "justdo_files" # Use underscores

  fs_id: "justdo-files"

  plugin_human_readable_name: "JustDo Files"

  files_count_task_doc_field_id: "p:justdo-files:files_count"

  # Note that the whitelist for preview types must be selected carefully, 
  # some file types such as text/html can cause XSS vulnerabilities
  preview_types_whitelist: [
    "application/pdf"
    "image/png"
    "image/gif"
    "image/jpeg"
    "image/bmp"
    "image/webp"
    "video/mp4"
    "video/mpeg"
    "video/webm"
    "video/quicktime"
    "video/x-msvideo"
    "video/x-ms-wmv"
    ]
  
  tasks_files_collection_name: "tasks_files"
  tasks_files_publication_name: "jdfTaskFiles"
  avatars_collection_name: "avatars_collection"

_.extend JustdoFiles,
  supported_collection_names: [
    JustdoFiles.tasks_files_collection_name
    JustdoFiles.avatars_collection_name
  ]

  fs_bucket_id_to_collection_meta: 
    tasks: 
      collection_name: JustdoFiles.tasks_files_collection_name
      publication_name: JustdoFiles.tasks_files_publication_name
    avatars: 
      collection_name: JustdoFiles.avatars_collection_name
      # Avatar collection doesn't have a publication
