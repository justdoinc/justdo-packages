_.extend JustdoFiles.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @_setupFilesCollection()
    @_registerFilesDriver()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return
  
  _registerFilesDriver: ->
    self = @

    tasks_files_driver_options = 
      getFileSizeLimit: -> self.options.max_file_size
      getFileLink: (options, cb) ->
        try
          link = self.getShareableLink(options.file_id)
        catch err
          cb err
          return

        cb null, link
        return
      instance: self
    
    if @_getEnvSpecificFsOptions?
      tasks_files_driver_options = _.extend tasks_files_driver_options, @_getEnvSpecificFsOptions()
      
    APP.justdo_file_interface.registerFs "#{JustdoFiles.fs_id}-tasks-files", tasks_files_driver_options
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

  _requireFileIdAndCollectionName: (file_id, collection_name) ->
    check file_id, String
    # The triple dot (...) is the spread operator in CoffeeScript
    # It expands the array JustdoFiles.supported_collection_names into individual arguments
    # So Match.OneOf receives each collection name as a separate argument
    check collection_name, Match.OneOf(JustdoFiles.supported_collection_names...)
    return true

  _isFileExist: (file_id, collection_name) ->
    @_requireFileIdAndCollectionName(file_id, collection_name)

    return @[collection_name].findOne(file_id)?

  isFileExist: (file_id) ->
    return @_isFileExist(file_id, "tasks_files")

  isAvatarExist: (file_id) ->
    return @_isFileExist(file_id, "avatars_collection")

  _getFileShareableLink: (file_id, collection_name) ->
    @_requireFileIdAndCollectionName(file_id, collection_name)
    return @[collection_name].findOne(file_id).link()

  getShareableLink: (file_id) ->
    return @_getFileShareableLink(file_id, "tasks_files")

  getAvatarShareableLink: (file_id) ->
    return @_getFileShareableLink(file_id, "avatars_collection")

  _getFilePreviewLink: (file_id, collection_name) ->
    @_requireFileIdAndCollectionName(file_id, collection_name)

    file = @[collection_name].findOne(file_id)
    preview_link = file.link() + "?preview=true"

    if @isFileTypePdf(file.type)
      # We found out that in some machines caching might cause an issue with pdf previews,
      # to avoid that, we use a random string in a custom GET param to prevent caching.
      preview_link += "&r=#{Math.ceil(Math.random() * 100000000)}"

    return preview_link

  getFilePreviewLink: (file_id) ->
    return @_getFilePreviewLink(file_id, "tasks_files")

  getAvatarPreviewLink: (file_id) ->
    return @_getFilePreviewLink(file_id, "avatars_collection")

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
        self.emit "tasks-files-before-upload", file
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

    @avatars_collection = new FilesCollection
      debug: false

      collectionName: "user_avatars"

      allowClientCode: false

      downloadRoute: "/user-avatars/download"

      protected: false

      onBeforeUpload: (file) ->
        if file.size <= self.options.max_file_size
          return true

        return "Maximum file size is #{self._getMaxFileSizeInMb()}MB"

      onAfterRemove: (files_obj) ->
        for file_obj in files_obj
          gfs_id = file_obj.meta.gridfs_id

          self.removeGridFsId(gfs_id)

        return

    return

  isFileTypePreviewable: (file_type) ->
    return file_type in JustdoFiles.preview_types_whitelist

  isFileTypeVideo: (file_type) ->
    return file_type.indexOf("video") is 0

  isFileTypeImage: (file_type) ->
    return file_type.indexOf("image") is 0

  isFileTypePdf: (file_type) ->
    return file_type is "application/pdf"
