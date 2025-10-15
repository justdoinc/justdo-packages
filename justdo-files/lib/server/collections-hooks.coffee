_.extend JustdoFiles.prototype,
  _setupCollectionsHooks: ->
    # Cleanup files before removing tasks, to prevent orphaned files from
    # existing in our storage
    @tasks_collection.before.remove (userId, doc) =>
      @tasks_files.remove({"meta.task_id": doc._id})

      return

    @setupChangeLogCapture()

    return
  
  setupChangeLogCapture: ->
    self = @
    
    self.tasks_files.collection.after.insert (user_id, file_doc) ->
      APP.tasks_changelog_manager.logChange
        field: "justdo_tasks_files.#{file_doc._id} upload"
        label: "File"
        change_type: JustdoFiles.file_upload_change_type
        task_id: file_doc.meta.task_id
        by: file_doc.userId
        undo_disabled: true
        bypass_time_filter: true
        data:
          file_metadata: file_doc
    
    self.tasks_files.collection.after.update (userId, file_doc, fieldNames, modifier, options) ->
      if (new_filename = modifier.$set?.name)?
        old_file_doc = @previous
        APP.tasks_changelog_manager.logChange
          field: "justdo_tasks_files.#{file_doc._id} rename"
          label: "File"
          change_type: JustdoFiles.file_rename_change_type
          task_id: file_doc.meta.task_id
          by: file_doc.userId
          undo_disabled: true
          bypass_time_filter: true
          old_value: old_file_doc.name
          new_value: new_filename
          data:
            # Despite the new file_doc is readily available here, we store the old file_doc
            # to be consistent with the behaviour of the tasks-file-manager package,
            # to make future changes easier.
            file_metadata: old_file_doc
    
    self.tasks_files.collection.after.remove (user_id, file_doc) ->
      APP.tasks_changelog_manager.logChange
        field: "justdo_tasks_files.#{file_doc._id} remove"
        label: "File"
        change_type: JustdoFiles.file_remove_change_type
        task_id: file_doc.meta.task_id
        by: file_doc.userId
        undo_disabled: true
        bypass_time_filter: true
        data:
          file_metadata: file_doc
    
    return