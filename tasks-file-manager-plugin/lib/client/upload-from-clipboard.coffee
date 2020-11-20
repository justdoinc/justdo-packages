_.extend TasksFileManager.prototype,
  _retrieveImageFromClipboardAsBlob: (pasteEvent, callback) ->
    if pasteEvent.clipboardData == false
      JustdoHelpers.callCb callback, undefined

      return

    if not (items = (pasteEvent.clipboardData or pasteEvent.originalEvent.clipboardData).items)?
      JustdoHelpers.callCb callback, undefined

      return

    for item in items
      # Skip content if not image
      if /image/.test item.type
        # Retrieve image on clipboard as blob
        blob = item.getAsFile()
        JustdoHelpers.callCb callback, blob

    return

  _setupPasteEventListener: ->
    # If any of the restricted targets is currently focused, we skip the paste procedure
    restricted_targets = ["#task-description-container", "textarea,input"]

    window.addEventListener "paste", (e) =>
      if JustdoHelpers.currentPageName() == "project"
        if (gc = APP.modules.project_page.gridControl())? and (current_row = gc.getCurrentRow())?
          if gc._grid_data.getItemIsCollectionItem(current_row)
            if $(e.target).closest(restricted_targets.join(",")).length
              return

            @_retrieveImageFromClipboardAsBlob e, (image_blob) =>
              if image_blob?
                dropEvent = $.Event("drop")

                dropEvent.originalEvent =
                  "dataTransfer":
                    files: [ image_blob ]

                APP.modules.project_page.setCurrentTaskPaneSectionId("tasks-file-manager")

                Tracker.flush()

                setTimeout ->
                  $('.drop-pane').trigger dropEvent

                  return
                , 100 # XXX this isn't a good solution, there's a need to make getUploadPolicy call a callback once it is ready and only then upload files.

              return

      return
    , false

    return
