Template.tasks_file_manager_files.onCreated ->
  tpl = @

  @renaming = new ReactiveVar false
  @deletion = new ReactiveVar false
  @bulk_edit_mode_rv = new ReactiveVar false
  @bulk_selected_rv = new ReactiveVar []

  @getTypeCssClass = (file_type) ->
    [p1, p2] = file_type.split('/')
    if not p2?
      return p1
    else
      return p2.replace(/\./, "_")

    return

  @bulkEditModeEnable = ->
    tpl.bulk_edit_mode_rv.set true
    tpl.renaming.set false

    return

  @bulkEditModeDisable = ->
    tpl.bulk_edit_mode_rv.set false
    tpl.bulk_selected_rv.set []

    return

  @removeFiles = (files) ->
    tpl.bulkEditModeDisable()

    for file_id in files
      APP.tasks_file_manager_plugin.tasks_file_manager.removeFile JD.activeItemId(), file_id, (err, result) ->
        if err
          console.log err

    return

  @bulkEditSelect = (file_id) ->
    selected_files = tpl.bulk_selected_rv.get()

    if selected_files.includes file_id
      selected_files.splice selected_files.indexOf(file_id), 1
    else
      selected_files.push file_id

    tpl.bulk_selected_rv.set selected_files

    return

  @print_files = ->
    $("body").append """<div class="print-files-mode-overlay"></div>"""

    $print_files_mode_overlay = $(".print-files-mode-overlay")
    files = $(".tasks-file-manager-files .file")
    html = ""

    for file in files
      title = $(file).find(".title a").text()
      date = $(file).find(".date").attr("title")
      image_preview = $(file).find(".image-preview")

      file_html = """
        <h1>Files :: #{JustdoHelpers.taskCommonName(APP.collections.Tasks.findOne(@data.task_id), 120)}</h1><br>
        <div class="print-files-item">
          <h2>#{JustdoHelpers.xssGuard(title)}</h2>
          <h3>#{JustdoHelpers.xssGuard(date)}</h3>
        """
      if $(image_preview)[0]?
        image_url = $(image_preview).css("background-image").replace(/^url\(['"](.+)['"]\)/, "$1")
        file_html += """
          <img class="print-files-item-image" src="#{image_url.replace(/"/g, "")}" alt="#{JustdoHelpers.xssGuard(title)}">
        """

      file_html += """</div>"""
      html += file_html

    $print_files_mode_overlay.html html
    window.print()
    $print_files_mode_overlay.remove()

    return

  return

DISPLAYED_FILE_TYPES = {
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx"
  "application/vnd.openxmlformats-officedocument.presentationml.presentation": "pptx"
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "xlsx"
}

Template.tasks_file_manager_files.helpers
  renaming: -> Template.instance().renaming.get() == this.file.id
  deletion: -> Template.instance().deletion.get() == this.file.id
  size: -> JustdoHelpers.bytesToHumanReadable(this.file.size)

  files: ->
    if (files_arr = Template.instance().data.files)?
      return files_arr.sort (f1, f2) -> f2.date_uploaded - f1.date_uploaded
    return

  displayedFileType: (mine_type) ->
    if (name = DISPLAYED_FILE_TYPES[mine_type])?
      return name
    return mine_type

  shareableLink: () ->
    task = @task
    file = @file
    APP.tasks_file_manager_plugin.tasks_file_manager.getShareableLink task.task_id, file.id, ""

  tempPlaceHolder: ->
    task = @task
    file = @file

    placeholder = "tfm_img_placeholder_#{task.task_id}_#{file.id}"

    tpl = Template.instance()

    APP.tasks_file_manager_plugin.tasks_file_manager.getPreviewDownloadLink task.task_id, file.id, 1, {width: 512, cropHeightForNonImgSrc: 256, output: "jpg"}, (err, link) =>
      # Load the image
      load_element = $("<img/>").attr("src", link).on "load", =>
        # On load, set as the element's background
        tpl.$(".#{placeholder}")
          .css("background-image", "url(#{link})")
          .removeClass("loading")
          .addClass("image-preview")

        load_element.remove()

        return

      return

    return placeholder

  isPreviewSupported: ->
    return  APP.tasks_file_manager_plugin.tasks_file_manager.isConversionSupported @file.type, "jpg"

  typeClass: ->
    return Template.instance().getTypeCssClass(@file.type)

  bulkEditMode: ->
    return Template.instance().bulk_edit_mode_rv.get()

  bulkSelectedExist: ->
    selected_count = Template.instance().bulk_selected_rv.get().length
    return selected_count > 0

  bulkSelectedFile: ->
    selected_files = Template.instance().bulk_selected_rv.get()

    return selected_files.includes @file.id

  bulkSelectedCount: ->
    return Template.instance().bulk_selected_rv.get().length

  bulkSelectedCountGreaterThanOne: ->
    selected_count = Template.instance().bulk_selected_rv.get().length
    return selected_count > 1

Template.tasks_file_manager_files.events
  "click .file-download-link": (e, tmpl) ->
    e.preventDefault()
    task = @task
    file = @file

    APP.tasks_file_manager_plugin.showPreviewOrStartDownload(task.task_id, file)

    return

  "click .file-rename-link": (e, tmpl) ->
    e.preventDefault()
    tmpl.renaming.set @file.id
    Meteor.defer ->
      tmpl.$("[name='title']").focus()

    return

  "keypress [name='title']": (e, tmpl) ->
    if e.which == 13 # enter key
      tmpl.$('.file-rename-done').click()

    return

  "click .file-direct-download-link": (e, tmpl) ->
    APP.tasks_file_manager_plugin.tasks_file_manager.downloadFile @task.task_id, @file.id, (err, url) ->
      if err then console.log(err)

    return

  "click .file-rename-done": (e, tmpl) ->
    e.preventDefault()
    task = @task
    file = @file
    newTitle = tmpl.$("[name='title']").val()
    APP.tasks_file_manager_plugin.tasks_file_manager.renameFile task.task_id, file.id, newTitle, (err, result) ->
      # TODO: emit an error event.
      if err
        console.log(err)
      else
        tmpl.renaming.set false
      return

    return

  "click .file-rename-cancel": (e, tmpl) ->
    e.preventDefault()
    tmpl.renaming.set false

    return

  "click .file-remove-link": (e, tmpl) ->
    e.preventDefault()
    tmpl.deletion.set @file.id

    return

  "click .msg-ok": (e, tmpl) ->
    e.preventDefault()
    task = @task
    file = @file
    tmpl.$(".msg .msg-content").hide()
    APP.tasks_file_manager_plugin.tasks_file_manager.removeFile task.task_id, file.id, (err, result) ->
      if err
        console.log err

    return

  "click .msg-cancel": (e, tmpl) ->
    e.preventDefault()
    tmpl.deletion.set false

    return

  "keydown .file input": (e, tmpl) ->
    if e.which == 27
      tmpl.renaming.set false

    return

  "click .tasks-file-manager-print": (e, tmpl) ->
    tmpl.print_files()

    return

  "click .bulk-edit-done": (e, tpl) ->
    tpl.bulkEditModeDisable()

    return

  "click .file-edit-dropdown-select": (e, tpl) ->
    tpl.bulkEditModeEnable()
    tpl.bulkEditSelect(@file.id)

    return

  "click .edit-mode .file": (e, tpl) ->
    tpl.bulkEditSelect(@file.id)

    return

  "click .bulk-edit-remove": (e, tpl) ->
    selected_files = tpl.bulk_selected_rv.get()
    selected_files_count = selected_files.length

    if selected_files_count > 1
      bootbox.confirm "Are you sure you want to remove <b>#{selected_files.length}</b> files?", (result) ->
        if result
          tpl.removeFiles(selected_files)
    else
      tpl.removeFiles(selected_files)

    return
