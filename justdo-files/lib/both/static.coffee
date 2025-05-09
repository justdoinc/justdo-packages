_.extend JustdoFiles,
  project_custom_feature_id: "justdo_files" # Use underscores

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
  
  default_file_upload_options:
    chunkSize: "dynamic"
    transport: "ddp"
