_.extend TasksFileManagerPlugin.prototype,
  _registerFilesDriver: ->
    self = @

    if Meteor.isClient
      await @filestackReadyDfd.promise()

    APP.getEnv (env) ->
      tasks_files_driver_options = 
        getFileSizeLimit: -> env.FILESTACK_MAX_FILE_SIZE_BYTES
        instance: self.tasks_file_manager

      APP.justdo_file_interface.registerFs "#{TasksFileManagerPlugin.fs_id}-tasks-files", tasks_files_driver_options

      return

    return

