isPdfPreview = (file_type) ->
  file_type.indexOf("application/pdf") == 0

isImagePreview = (file_type) ->
  file_type.indexOf("image/") == 0

isVideoPreview = (file_type) ->
  file_type.indexOf("video/") == 0

Template.tasks_file_manager_files_preview.onCreated ->
  @active_file_rv = new ReactiveVar @data.file
  @sorted_previewable_files_under_task_rv = new ReactiveVar []
  @preview_link_rv = new ReactiveVar ""
  @active_file_index_rv = new ReactiveVar 0
  @tasks_augmented_fields_sub = JD.subscribeItemsAugmentedFields [@data.task_id], ["files"]

  @autorun =>
    if not @tasks_augmented_fields_sub.ready()
      return

    files = APP.collections.TasksAugmentedFields.findOne(@data.task_id, {fields: {files: 1}})?.files
    previewable_files_under_task = _.chain files
      .filter (file) => 
        is_file_previewable = APP.tasks_file_manager_plugin.tasks_file_manager.isConversionSupported(file.type, "jpg") or APP.tasks_file_manager_plugin.tasks_file_manager.isConversionSupported(file.type, "pdf") or (file.type.indexOf("video/") is 0)
        is_file_in_file_ids_to_show = true
        if not _.isEmpty @data.file_ids_to_show
          is_file_in_file_ids_to_show = file.id in @data.file_ids_to_show
        return is_file_previewable and is_file_in_file_ids_to_show
      .sortBy "date_uploaded"
      .value()
      .reverse()
    @sorted_previewable_files_under_task_rv.set previewable_files_under_task
    return

  @autorun =>
    active_file = @active_file_rv.get()
    previewable_files_under_task = @sorted_previewable_files_under_task_rv.get()

    preview_options = null
    @preview_link_rv.set null
    if isImagePreview active_file.type
      preview_options =
        output: "jpg"
        width: 1024
    else if isPdfPreview active_file.type
      preview_options =
        output: "pdf"
    else if isVideoPreview active_file.type
      preview_options =
        output: "mp4"
    if preview_options?
      APP.tasks_file_manager_plugin.tasks_file_manager.getPreviewDownloadLink @data.task_id, active_file.id, 1, preview_options, (err, link) =>
        if err?
          JustdoSnackbar.show
            text: err.reason or err
          return

        @preview_link_rv.set(link)
        return

    @active_file_index_rv.set _.findIndex previewable_files_under_task, (file_doc) -> file_doc.id is active_file.id
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
    $(".modal-title").text updated_active_file.title
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
    $(".modal-title").text updated_active_file.title
    return

  return

Template.tasks_file_manager_files_preview.onRendered ->
  $(".tasks-file-manager-preview-dialog").on "keydown", (e) =>
    if e.key in ["ArrowLeft", "ArrowUp"]
      @showPrevFile()
    if e.key in ["ArrowRight", "ArrowDown"]
      @showNextFile()
    return
  return

Template.tasks_file_manager_files_preview.helpers
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

  isImagePreview: -> isImagePreview Template.instance().active_file_rv.get().type

  isPdfPreview: -> isPdfPreview Template.instance().active_file_rv.get().type

  isVideoPreview: -> isVideoPreview Template.instance().active_file_rv.get().type

  fileTitle: -> Template.instance().active_file_rv.get().title

  randomString: ->
    # We found out that in some machines caching might cause an issue with pdf previews,
    # to avoid that, we use a random string in a custom GET param to prevent caching.

    return Math.ceil(Math.random() * 100000000)

  preview_link: ->
    tpl = Template.instance()

    return tpl.preview_link_rv.get()

Template.tasks_file_manager_files_preview.events
  "click .prev-file": (e, tpl) ->
    tpl.showPrevFile()
    return

  "click .next-file": (e, tpl) ->
    tpl.showNextFile()
    return

Template.tasks_file_manager_files_preview.onDestroyed ->
  @tasks_augmented_fields_sub?.stop?()
  return
