_.extend JustdoFiles.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @setupRouter()

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

  _setupFilesCollection: ->
    @tasks_files = new FilesCollection
      collectionName: "justdo_tasks_files"
      allowClientCode: false
      downloadRoute: "/justdo-tasks-files/download"
      onBeforeUpload: (file) ->
        if file.size <= JustdoFiles.max_file_size
          console.log "uploading..."
          return true
        
        return "Maximum file size is 100MB"

    return