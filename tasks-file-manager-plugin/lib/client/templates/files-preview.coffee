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
  isPdf: -> @file.type == "application/pdf"
  isImage: -> @file.type.indexOf("image") == 0

  preview_link: ->
    tpl = Template.instance()

    return tpl.preview_link.get()