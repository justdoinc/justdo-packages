import Grid from "gridfs-stream"
import fs from "fs"
import { MongoInternals } from "meteor/mongo"

_.extend JustdoFiles.prototype,
  _immediateInit: ->
    @gfs = Grid MongoInternals.defaultRemoteCollectionDriver().mongo.db, MongoInternals.NpmModule

    @_setupOstrioFiles()

    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  tasksFilesPublicationHandler: (publish_this, task_id, user_id) ->
    check task_id, String
    check user_id, String

    if _.isEmpty(task_id)
      publish_this.stop()

      return

    if _.isEmpty(user_id)
      publish_this.stop()

      return

    if not @isUserAllowedToAccessTasksFiles(task_id, user_id)
      publish_this.stop()

      return

    return @tasks_files.find({"meta.task_id": task_id}).cursor

  _setupOstrioFiles: ->
    justdo_files_this = @
    gfs = @gfs

    @tasks_files.onAfterUpload = (file) ->
      tasks_files_this = @

      writestream = gfs.createWriteStream
        filename: file.name
        content_type: file.mime

      fs.createReadStream(file.path).pipe writestream

      writestream.on "close", Meteor.bindEnvironment (gridfs_file) =>
        removed_before_linking = false

        try
          gfs_id = gridfs_file._id.toString()

          if (file_obj = tasks_files_this.collection.findOne file._id)?
            # Link gridfs_id
            tasks_files_this.collection.update file._id,
              $set:
                "meta.gridfs_id": gfs_id
                "meta.upload_date": new Date()
          else
            # FILE REMOVED BEFORE LINKING! remove the gfs_id
            removed_before_linking = true
            justdo_files_this.removeGridFsId(gfs_id)
        catch e
          tasks_files_this.collection.remove file._id
        finally
          if not removed_before_linking
            # Remove the temporary file, now that we stored it in mongodb
            tasks_files_this.unlink tasks_files_this.collection.findOne file._id

          return

        return

      return

    @tasks_files.interceptDownload = (http, file, versionName) =>
      gridfs_id = file.meta.gridfs_id

      if gridfs_id?
        readstream = gfs.createReadStream
          _id: gridfs_id
        readstream.on "error", (err) ->
          throw err
        http.response.setHeader "Content-Disposition", "attachment; filename=\"#{file.name}\""
        readstream.pipe http.response

      # Returning true means that we took control (intercepted the behavior), if we
      # got gridfs_id, we started streaming it already, so, we took contorl...
      return gridfs_id?

  removeFile: (file_id, user_id) ->
    if not (file_obj = @tasks_files.findOne(file_id))?
      throw @_error "unknown-file"

    task_id = file_obj.meta.task_id
    gfs_id = file_obj.meta.gridfs_id

    if not @isUserAllowedToAccessTasksFiles(task_id, user_id)
      throw @_error "unknown-file"

    @tasks_files.remove(file_id)

    return

  removeGridFsId: (gfs_id) ->
    if not gfs_id?
      return

    @gfs.remove {_id: gfs_id}, (err) ->
      if (err)
        throw err

    return
  
  renameFile: (file_id, new_filename, user_id) ->
    if not (file_obj = @tasks_files.findOne(file_id))?
        throw @_error "unknown-file"

      task_id = file_obj.meta.task_id

      if not @isUserAllowedToAccessTasksFiles(task_id, user_id)
        throw @_error "unknown-file"

      new_filename_split = new_filename.split "."
      new_ext = if new_filename_split.length <= 1 then "" else new_filename_split[new_filename_split.length-1]
      if new_ext != file_obj.ext
        new_filename += ".#{file_obj.ext}"

      @tasks_files.update file_id, 
        $set:
          name: new_filename

      return
