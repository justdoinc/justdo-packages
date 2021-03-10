_.extend JustdoFiles.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @_setupFilesCollection()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(JustdoFiles.project_custom_feature_id, project_doc)

  getProjectDocIfPluginInstalled: (project_id) ->
    return @projects_collection.findOne({_id: project_id, "conf.custom_features": JustdoFiles.project_custom_feature_id})

  isUserAllowedToAccessTasksFiles: (task_id, user_id) ->
    check task_id, String
    check user_id, String

    if _.isEmpty(user_id) or _.isEmpty(task_id)
      return false

    if not @tasks_collection.findOne({_id: task_id, users: user_id})?
      return false

    return true

  isFileExist: (file_id) ->
    check file_id, String
    return @tasks_files.findOne(file_id)?

  getShareableLink: (file_id) ->
     check file_id, String
     return @tasks_files.findOne(file_id).link()

  _getMaxFileSizeInMb: -> Math.floor(@options.max_file_size * 0.00000095367432)

  _setupFilesCollection: ->
    self = @

    @tasks_files = new FilesCollection
      debug: false

      collectionName: "justdo_tasks_files"

      allowClientCode: false

      downloadRoute: "/justdo-tasks-files/download"

      protected: (file) ->
        # A user can download a file only if he is a member of the task to which it is
        # associated.

        user_id = @user()?._id
        task_id = file.meta.task_id

        if not user_id?
          return 403

        if not self.isUserAllowedToAccessTasksFiles(task_id, user_id)
          return 403

        return true

      onBeforeUpload: (file) ->
        if not self.tasks_collection.findOne(file.meta.task_id, {fields: {_id: 1}})
          return "You don't have permission to upload files to this task"

        if file.size <= self.options.max_file_size
          return true
        
        return "Maximum file size is #{self._getMaxFileSizeInMb()}MB"

      onAfterRemove: (files_obj) ->
        for file_obj in files_obj
          gfs_id = file_obj.meta.gridfs_id

          self.removeGridFsId(gfs_id)

        return


    return
