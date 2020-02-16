isPdfPreview = (file_type) ->
  APP.tasks_file_manager_plugin.tasks_file_manager.isConversionSupported file_type, "pdf"

isImagePreview = (file_type) ->
  file_type.indexOf("image/") == 0

Template.tasks_file_manager_files_preview.onCreated ->
  @preview_link = new ReactiveVar null

  preview_options = null
  if isImagePreview @data.file.type
    preview_options =
      output: "jpg"
      width: 1024
  else if isPdfPreview @data.file.type
    preview_options = 
      output: "pdf"

  if preview_options?
    APP.tasks_file_manager_plugin.tasks_file_manager.getPreviewDownloadLink @data.task_id, @data.file.id, 1, preview_options, (err, link) =>
      if err?
        alert("Error occured: #{err.reason}")

        return

      @preview_link.set(link)

      return

  return

Template.tasks_file_manager_files_preview.helpers
  isImagePreview: -> isImagePreview @file.type

  isPdfPreview: -> isPdfPreview @file.type
  

  randomString: ->
    # We found out that in some machines caching might cause an issue with pdf previews,
    # to avoid that, we use a random string in a custom GET param to prevent caching.

    return Math.ceil(Math.random() * 100000000)

  preview_link: ->
    tpl = Template.instance()

    return tpl.preview_link.get()