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
        change_type: "custom"
        task_id: file_doc.meta.task_id
        by: file_doc.userId
        message: "uploaded file - #{file_doc.name}"
    
    self.tasks_files.collection.after.update (userId, file_doc, fieldNames, modifier, options) ->
      if (new_filename = modifier.$set?.name)?
        APP.tasks_changelog_manager.logChange
          field: "justdo_tasks_files.#{file_doc._id} rename"
          label: "File"
          change_type: "custom"
          task_id: file_doc.meta.task_id
          by: file_doc.userId
          message: "rename a file to #{new_filename}"
    
    self.tasks_files.collection.after.remove (user_id, file_doc) ->
      APP.tasks_changelog_manager.logChange
        field: "justdo_tasks_files.#{file_doc._id} remove"
        label: "File"
        change_type: "custom"
        task_id: file_doc.meta.task_id
        by: file_doc.userId
        message: "removed file - #{file_doc.name}"
    
    return