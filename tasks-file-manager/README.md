# Just Do Tasks File Manager

Upload, store, download and manage files attached to tasks.

## Usage

1. Initialize the File Manager on both the client and the server:

  ```coffee
  tasks_file_manager = new TasksFileManager
    tasks_collection: Tasks
    api_key: "your-filestack-api-key"
    secret: Meteor.isServer? and "your-filestack-secret"
  ```

2. On the client, initialize a drop pane for each task that the user can see and upload files to:

  ```coffee
  Template.FileUpload.onCreated ->
    @pickerPane = APP.tasks_file_manager.makeDropPane @data.task_id

  Template.FileUpload.onRendered ->
    @pickerPane.initPane @$(".drop-pane")[0]
  ```

3. For each drop pane, use the available reactive variables to display feedback to your users:

  ```coffee
  Template.FileUpload.helpers
    uploadMessage: ->
      tmpl = Template.instance()
      state = tmpl.pickerPane.status()
      return switch state
        when "loading"
          "..."
        when "ready"
          "Drag to upload. -or- Click to select files."
        when "hovering"
          "Drop to upload."
        when "success"
          "File uploaded! Click or drag-n-drop to upload another."
        when "error"
          tmpl.pickerPane.error()
        when "uploading"
          "Uploading..."

    hoverClass: ->
      tmpl = Template.instance()
      state = tmpl.pickerPane.status()
      return "drop-pane-hover" if state == "hovering"

    percentage: ->
      tmpl = Template.instance()
      return tmpl.pickerPane.percentage()
  ```

4. Build UI to handle Remove, Rename, and Download actions, for each action call the appropriate fileManager api call:

  ```coffee
  Template.FileItem.events
    "click .file-download-link": (e, tmpl) ->
      e.preventDefault()
      task = this.task
      tasks_file_manager.downloadFile task.task_id, @id, (err, url) ->
        if err then console.log(err)
    "click .file-rename-done": (e, tmpl) ->
      e.preventDefault()
      task = this.task
      file = this.file
      newTitle = tmpl.$("[name='title']").val()
      tasks_file_manager.renameFile task.task_id, file.id, newTitle, (err, result) ->
        if err
          console.log(err)
        return
    "click .file-remove-link": (e, tmpl) ->
      e.preventDefault()
      task = this.task
      file = this.file

      if confirm("Are you sure you want to remove this file #{file.title}?")
        APP.tasks_file_manager.removeFile task.task_id, file.id, (err, result) ->
          if err
            console.log err
  ```

5. You may want to use the File Manager's 'getDownloadLink' api method directly if you want to display files in your UI, for example to display the first image as a task thumbnail:

  ```coffee
  Template.TaskItem.onCreated ->
    @previewUrl = new ReactiveVar()
    @autorun =>
      task = Template.currentData().task
      files = task?.files
      previewFile = _.find files, (file) -> /^image/.test file.type

      if previewFile
        APP.tasks_file_manager.getDownloadLink task._id, previewFile.id
        ,
          (error, url) =>
            if error
              console.log(error)
            else
              @previewUrl.set(url)

  Template.TaskItem.helpers
    previewUrl: ->
      Template.instance().previewUrl.get()
  ```

Notes
---

1. Meteor DDP Method Simulation Issue:

  I noticed a weird issue with Meteor and DDP, apparently it's possible for a Template's onCreate callbacks to be called in the context of a Meteor Simulation, in this case any meteor method calls you make will return immediately.

  Originally I solved this issue by wrapping my code in a setTimeout, however a better solution turned out to be to move the Meteor method call into the onRendered callback, which is not called until after the meteor method simulation has finished.

  Be aware of this issue if you change when DropPane.prototype.refreshToken is called.

2. File remove will remove the file both from the app's mongo collection and from the underlying source (filestack and S3), however this operation is not atomic, and different errors might mean that the file was removed from filestack, but not from the app's mongo collection. XXX - Future calls to remove the file will fail so you'll need to clean this situation up manually.
3. My research indicates that file upload cannot be cancelled, and there's no mention in filestack's documentation of any mechanism for doing so.
