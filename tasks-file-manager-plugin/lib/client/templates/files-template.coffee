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

  return

Template.tasks_file_manager_files.helpers
  renaming: -> Template.instance().renaming.get() == this.file.id
  deletion: -> Template.instance().deletion.get() == this.file.id
  size: -> JustdoHelpers.bytesToHumanReadable(this.file.size)

  shareableLink: () ->
    task = @task
    file = @file
    APP.tasks_file_manager_plugin.tasks_file_manager.getShareableLink task.task_id, file.id, ""

  tempPlaceHolder: ->
    task = @task
    file = @file

    placeholder = "tfm_img_placeholder_#{task.task_id}_#{file.id}"

    tpl = Template.instance()

    APP.tasks_file_manager_plugin.tasks_file_manager.getDownloadLink task.task_id, file.id, (err, link) =>
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

  isImage: ->
    if (@file.type.slice(0,6) == "image/")
      return true

    return false

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
    tmpl.$(".loader").show()
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
