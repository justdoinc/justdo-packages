_.extend TasksFileManagerPlugin,
  fs_id: "filestack"

  # Used only in conjunction with justdo-file-interface
  tasks_files_collection_name: "tfm_tasks_files"

  tasks_files_publication_name: "tfmTaskFiles"

  previewable_categories_whitelist: [
    "image"
    "video"
    "pdf"
  ]