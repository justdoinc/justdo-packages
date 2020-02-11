Template.tasks_file_manager_files_preview.onCreated ->
  @preview_link = new ReactiveVar null

  APP.tasks_file_manager_plugin.tasks_file_manager.getPreviewDownloadLink @data.task_id, @data.file.id, 1, {width: 1024}, (err, link) =>
    if err?
      alert("Error occured: #{err.reason}")

      return

    @preview_link.set(link)

    return

  return

Template.tasks_file_manager_files_preview.helpers
  isPdfPreview: -> @file.type in  ["application/pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",    # docx
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",  # pptx
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"           # xlsx
  ]
  
  isImage: -> @file.type.indexOf("image") == 0

  randomString: ->
    # We found out that in some machines caching might cause an issue with pdf previews,
    # to avoid that, we use a random string in a custom GET param to prevent caching.

    return Math.ceil(Math.random() * 100000000)

  preview_link: ->
    tpl = Template.instance()

    return tpl.preview_link.get()