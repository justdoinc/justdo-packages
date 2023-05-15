Template.justdo_files_files_preview.onCreated ->
  @active_file_rv = new ReactiveVar @data.file
  @sorted_previewable_files_under_task_rv = new ReactiveVar []
  @preview_link_rv = new ReactiveVar ""
  @active_file_index_rv = new ReactiveVar 0

  @autorun =>
    previewable_files_under_task = APP.justdo_files.tasks_files.find({"meta.task_id": @data.task_id, type: {$in: JustdoFiles.preview_supported_formats}}, {sort: {"meta.upload_date": -1}}).fetch()
    @sorted_previewable_files_under_task_rv.set previewable_files_under_task
    return

  @autorun =>
    active_file = @active_file_rv.get()
    previewable_files_under_task = @sorted_previewable_files_under_task_rv.get()

    @preview_link_rv.set APP.justdo_files.tasks_files.findOne(active_file._id).link() + "?preview=true"
    @active_file_index_rv.set _.findIndex previewable_files_under_task, (file_doc) -> file_doc._id is active_file._id
    return

  @showPrevFile = ->
    previewable_files_under_task = @sorted_previewable_files_under_task_rv.get()
    new_index = @active_file_index_rv.get() - 1

    if new_index < 0
      new_index = 0

    updated_active_file = previewable_files_under_task[new_index]
    @active_file_rv.set updated_active_file
    $(".modal-title").text updated_active_file.name
    return

  @showNextFile = ->
    previewable_files_under_task = @sorted_previewable_files_under_task_rv.get()
    previewable_files_count = previewable_files_under_task.length - 1
    new_index = @active_file_index_rv.get() + 1

    if new_index > previewable_files_count
      new_index = previewable_files_count

    updated_active_file = previewable_files_under_task[new_index]
    @active_file_rv.set updated_active_file
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

  isPdf: -> @file.type == "application/pdf"

  isImage: -> @file.type.indexOf("image") == 0

  randomString: ->
    # We found out that in some machines caching might cause an issue with pdf previews,
    # to avoid that, we use a random string in a custom GET param to prevent caching.

    return Math.ceil(Math.random() * 100000000)

  preview_link: ->
    tpl = Template.instance()

    return tpl.preview_link_rv.get()

Template.justdo_files_files_preview.events
  "click .prev-file": (e, tpl) ->
    tpl.showPrevFile()
    return

  "click .next-file": (e, tpl) ->
    tpl.showNextFile()
    return
