Template.tasks_file_manager_files.onCreated ->
  @renaming = new ReactiveVar false
  @deletion = new ReactiveVar false

  @getTypeCssClass = (file_type) ->
    [p1, p2] = file_type.split('/')
    if not p2?
      return p1
    else
      return p2.replace(/\./, "_")

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
  "keypress [name='title']": (e, tmpl) ->
    if e.which == 13 # enter key
      tmpl.$('.file-rename-done').click()
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
  "click .file-rename-cancel": (e, tmpl) ->
    e.preventDefault()
    tmpl.renaming.set false
  "click .file-remove-link": (e, tmpl) ->
    e.preventDefault()
    tmpl.deletion.set @file.id
  "click .msg-ok": (e, tmpl) ->
    e.preventDefault()
    task = @task
    file = @file
    tmpl.$(".msg .msg-content").hide()
    APP.tasks_file_manager_plugin.tasks_file_manager.removeFile task.task_id, file.id, (err, result) ->
      if err
        console.log err
  "click .msg-cancel": (e, tmpl) ->
    e.preventDefault()
    tmpl.deletion.set false
  "mouseenter .file": (e, tmpl) ->
    e.preventDefault()
    $(e.currentTarget).addClass "active"

  "mouseleave .file": (e, tmpl) ->
    e.preventDefault()
    $(".file").removeClass "active"

  "keydown .file input": (e, tmpl) ->
    if e.which == 27
      tmpl.renaming.set false

  "click .tasks-file-manager-print": (e, tmpl) ->
    tmpl.print_files()
    return
