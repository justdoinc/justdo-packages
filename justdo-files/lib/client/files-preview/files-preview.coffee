Template.justdo_files_files_preview.onCreated ->
  @active_file_rv = new ReactiveVar @data.file
  @sorted_previewable_files_under_task_rv = new ReactiveVar []
  @preview_link_rv = new ReactiveVar null
  @active_file_index_rv = new ReactiveVar 0

  @autorun =>
    previewable_files_under_task = APP.justdo_files.getPreviewableFilesUnderTask(@data.task_id)
    @sorted_previewable_files_under_task_rv.set previewable_files_under_task
    return

  @autorun =>
    active_file = @active_file_rv.get()
    previewable_files_under_task = @sorted_previewable_files_under_task_rv.get()

    @preview_link_rv.set APP.justdo_files.getFilePreviewLink(active_file._id)
    @active_file_index_rv.set _.findIndex previewable_files_under_task, (file_doc) -> file_doc._id is active_file._id
    return

  @showPrevFile = ->
    previewable_files_under_task = @sorted_previewable_files_under_task_rv.get()
    cur_index = @active_file_index_rv.get()
    
    if cur_index is 0
      return

    if (new_index = cur_index - 1) < 0
      new_index = 0

    updated_active_file = previewable_files_under_task[new_index]
    @active_file_rv.set updated_active_file
    Tracker.flush()
    $(".modal-title").text updated_active_file.name
    return

  @showNextFile = ->    
    previewable_files_under_task = @sorted_previewable_files_under_task_rv.get()
    previewable_files_count = previewable_files_under_task.length - 1
    cur_index = @active_file_index_rv.get()

    if cur_index is previewable_files_count
      return

    if (new_index = cur_index + 1) > previewable_files_count
      new_index = previewable_files_count

    updated_active_file = previewable_files_under_task[new_index]
    @active_file_rv.set updated_active_file
    Tracker.flush()
    $(".modal-title").text updated_active_file.name
    return

  return

Template.justdo_files_files_preview.onRendered ->
  $(".justdo-files-preview-dialog").on "keydown", (e) =>
    if e.key in ["ArrowLeft", "ArrowUp"]
      @showPrevFile()
    if e.key in ["ArrowRight", "ArrowDown"]
      @showNextFile()
    return
  return

Template.justdo_files_files_preview.helpers
  activeFile: -> Template.instance().active_file_rv.get()

  isPrevButtonVisible: ->
    file_index = Template.instance().active_file_index_rv.get()
    if file_index <= 0
      return "invisible"
    return

  isNextButtonVisible: ->
    tpl = Template.instance()
    previewable_files_count = tpl.sorted_previewable_files_under_task_rv.get().length - 1
    file_index = tpl.active_file_index_rv.get()
    if file_index >= previewable_files_count
      return "invisible"
    return

  isPdf: -> APP.justdo_files.isFileTypePdf(@type)

  isImage: -> APP.justdo_files.isFileTypeImage(@type)

  isVideo: -> APP.justdo_files.isFileTypeVideo(@type)

  previewLink: ->
    tpl = Template.instance()

    return tpl.preview_link_rv.get()

Template.justdo_files_files_preview.events
  "click .prev-file": (e, tpl) ->
    tpl.showPrevFile()
    return

  "click .next-file": (e, tpl) ->
    tpl.showNextFile()
    return
