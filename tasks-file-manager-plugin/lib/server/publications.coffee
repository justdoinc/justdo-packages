_.extend TasksFileManagerPlugin.prototype,
  _setupPublications: -> 
    self = @

    Meteor.publish TasksFileManagerPlugin.tasks_files_collection_name, (task_id) ->
      check task_id, String
      check @userId, String
      
      if _.isEmpty(task_id)
        @stop()
        return

      if _.isEmpty(@userId)
        @stop()
        return       
      
      query = 
        _id: task_id
        users: @userId
        files: 
          $ne: null
      query_options = 
        fields:
          files: 1
      cursor = APP.collections.Tasks.find(query, query_options)

      published_file_ids_set = new Set()
      publishFile = (file) =>
        file.task_id = task_id
        file_id = file.id
        published_file_ids_set.add(file_id)
        @added("tfmTaskFiles", file_id, file)
      changeFile = (file) =>
        file.task_id = task_id
        file_id = file.id
        @changed("tfmTaskFiles", file_id, file)
      removeFile = (file_id) =>
        published_file_ids_set.delete(file_id)
        @removed("tfmTaskFiles", file_id)

      tracker = cursor.observeChanges
        added: (id, fields) =>
          # Publish files under a task as individual documents
          for file in fields.files
            publishFile(file)
        changed: (id, fields) =>
          # If a file is added/changed/removed, the entire task document we're observing will be changed.
          # That being said, Meteor will determine which files or field actually got changed,
          # so we don't need to diff the individual files ourselves.
          # Though we need to store the file ids to know which files got added/removed and publish accordingly.
          
          # file_ids stores the up-to-date file ids under the task.
          file_ids = []

          # Handle added/changed files
          for file in fields.files
            file_id = file.id
            file_ids.push(file_id)

            if published_file_ids_set.has(file_id)
              changeFile(file)
            else
              publishFile(file)

          # Handle removed files
          removed_file_ids = _.difference(Array.from(published_file_ids_set), file_ids)
          for file_id in removed_file_ids
            removeFile(file_id)

          # Update the set of published file ids
          for file_id in file_ids
            published_file_ids_set.add(file_id)
          
          return
        removed: (id) =>
          # The task got removed. Remove all the files published for this task.
          for file_id in Array.from(published_file_ids_set)
            removeFile(file_id)
          published_file_ids_set.clear()
          
      @onStop =>
        tracker.stop()
        return
      
      @ready()

    return
