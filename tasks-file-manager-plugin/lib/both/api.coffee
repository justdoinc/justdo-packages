_.extend TasksFileManagerPlugin.prototype,
  _registerFilesDriver: ->
    self = @

    tasks_files_driver_options = {}
    
    if self._getEnvSpecificFsOptions?
      tasks_files_driver_options = _.extend tasks_files_driver_options, self._getEnvSpecificFsOptions()

    APP.justdo_file_interface.registerFs "#{TasksFileManagerPlugin.fs_id}-tasks-files", tasks_files_driver_options

    return

  _getCollectionName: ->
    if Meteor.isClient
      return "TasksAugmentedFields"

    if Meteor.isServer
      return "Tasks"

  _getPreviewableFileTypes: ->
    conv_matrix = @tasks_file_manager.getConversionMartix()
    preview_supported_formats = _.union conv_matrix["pdf"], conv_matrix["jpg"]

    return preview_supported_formats

  isFileTypePreviewable: (file_type) ->
    previewable_file_types = @_getPreviewableFileTypes()

    return (file_type in previewable_file_types) or (file_type.indexOf("video/") is 0)