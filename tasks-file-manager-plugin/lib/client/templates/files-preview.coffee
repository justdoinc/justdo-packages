Template.tasks_file_manager_files_preview.helpers
  isPdf: -> @file.type == "application/pdf"
  isImage: -> @file.type.indexOf("image") == 0