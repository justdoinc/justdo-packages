Template.justdo_files_files_preview.onCreated ->
  @preview_link = new ReactiveVar APP.justdo_files.tasks_files.findOne(@data.file._id).link() + "?preview=true"

Template.justdo_files_files_preview.helpers
  isPdf: -> @file.type == "application/pdf"
  isImage: -> @file.type.indexOf("image") == 0

  randomString: ->
    # We found out that in some machines caching might cause an issue with pdf previews,
    # to avoid that, we use a random string in a custom GET param to prevent caching.

    return Math.ceil(Math.random() * 100000000)

  preview_link: ->
    tpl = Template.instance()

    return tpl.preview_link.get()