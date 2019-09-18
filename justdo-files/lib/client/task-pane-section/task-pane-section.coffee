Template.task_pane_justdo_files_task_pane_section_section.helpers
  files: ->
    return APP.justdo_files.tasks_files.find
      "meta.task_id": Tracker.nonreactive -> APP.modules.project_page.activeItemId()

Template.task_pane_justdo_files_task_pane_section_section.events
  "change #file-input": (e, template) ->
    upload = APP.justdo_files.tasks_files.insert
      file: e.currentTarget.files[0],
      meta:
        task_id: Tracker.nonreactive -> APP.modules.project_page.activeItemId()
      streams: "dynamic"
      chunkSize: "dynamic"
    , false

    upload.on "end", (err, file_obj) ->
      if err?
        console.log err
        # XX files with zero bytes
        return 

      $("#file-input").val ""
      return

    upload.start()

    return