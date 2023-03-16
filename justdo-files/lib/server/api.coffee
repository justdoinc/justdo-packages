import Grid from "gridfs-stream"
import fs from "fs"
import { MongoInternals } from "meteor/mongo"
import JSZip from "jszip"

Fiber = Npm.require "fibers"

_.extend JustdoFiles.prototype,
  _immediateInit: ->
    @gfs = Grid MongoInternals.defaultRemoteCollectionDriver().mongo.db, MongoInternals.NpmModule

    @_setupOstrioFiles()
    @_setupFilesArchiveRoute()

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

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see TASKS_FILES_COLLECTION_TASK_ID_INDEX)
    #
    return @tasks_files.find({"meta.task_id": task_id}).cursor

  _setupOstrioFiles: ->
    justdo_files_this = @
    gfs = @gfs

    files_collection_onAfterUpload = (file) ->
      writestream = gfs.createWriteStream
        filename: file.name
        content_type: file.mime

      fs.createReadStream(file.path).pipe writestream

      writestream.on "close", Meteor.bindEnvironment (gridfs_file) =>
        removed_before_linking = false

        try
          gfs_id = gridfs_file._id.toString()

          if (file_obj = @collection.findOne file._id)?
            # Link gridfs_id
            @collection.update file._id,
              $set:
                "meta.gridfs_id": gfs_id
                "meta.upload_date": new Date()
          else
            # FILE REMOVED BEFORE LINKING! remove the gfs_id
            removed_before_linking = true
            justdo_files_this.removeGridFsId(gfs_id)
        catch e
          @collection.remove file._id
        finally
          if not removed_before_linking
            # Remove the temporary file, now that we stored it in mongodb
            @unlink @collection.findOne file._id

            # Used by task files collection only.
            if (task_id = file?.meta?.task_id)?
              APP.justdo_permissions.runCbInIgnoredPermissionsScope =>
                justdo_files_this.tasks_collection.update(task_id, {$inc: {"#{JustdoFiles.files_count_task_doc_field_id}": 1}})

                return

            # Used by avatar collection only.
            if file?.meta?.is_avatar
              avatar_user_id = file.userId
              APP.justdo_files.removeUserAvatar {exclude: file._id}, avatar_user_id

              # We store only the absolute path of the link to avatar in users collection
              # so that the avatar file can be cached by CDN if such is enabled.
              avatar_link = justdo_files_this.avatars_collection.findOne(file._id).link()
              avatar_path = new URL(avatar_link).pathname
              Meteor.users.update(avatar_user_id, {$set: {"profile.profile_pic": avatar_path}})
              return

          return

        return

      return

    files_collection_interceptDownload = (http, file, versionName) =>
      gridfs_id = file.meta.gridfs_id

      if gridfs_id?
        readstream = gfs.createReadStream
          _id: gridfs_id
        readstream.on "error", (err) ->
          throw err
        
        # URL with query string "preview=true" will make allow browsers to render the file instead of forcing browsers to download the file
        # Note that the whitelist for preview types must be selected carefully, 
        # some file types such as text/html can cause XSS vulnerabilities
        preview_types_whitelist = ["application/pdf", "image/png", "image/gif", "image/jpeg", "image/bmp"]

        if http.request.query.preview == "true" and file.type in preview_types_whitelist
          http.response.setHeader "Content-Disposition", "inline; filename=\"#{file.name}\""
        else
          http.response.setHeader "Content-Disposition", "attachment; filename=\"#{file.name}\""

        readstream.pipe http.response

      # Returning true means that we took control (intercepted the behavior), if we
      # got gridfs_id, we started streaming it already, so, we took contorl...
      return gridfs_id?

    @tasks_files.onAfterUpload = files_collection_onAfterUpload

    @tasks_files.interceptDownload = files_collection_interceptDownload

    @avatars_collection.onAfterUpload = files_collection_onAfterUpload

    @avatars_collection.interceptDownload = files_collection_interceptDownload

    return

  removeFile: (file_id, user_id) ->
    if not (file_obj = @tasks_files.findOne(file_id))?
      throw @_error "unknown-file"

    task_id = file_obj.meta.task_id
    gfs_id = file_obj.meta.gridfs_id

    if not @isUserAllowedToAccessTasksFiles(task_id, user_id)
      throw @_error "unknown-file"

    if file_obj.userId != user_id
      APP.justdo_permissions.requireTaskPermissions("justdo-files.remove-file-by-non-uploader", task_id, user_id)

    @tasks_files.remove(file_id)

    APP.justdo_permissions.runCbInIgnoredPermissionsScope =>
      @tasks_collection.update(task_id, {$inc: {"#{JustdoFiles.files_count_task_doc_field_id}": -1}})

      return

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

      if file_obj.userId != user_id
        APP.justdo_permissions.requireTaskPermissions("justdo-files.rename-file-by-non-uploader", task_id, user_id)

      new_filename_split = new_filename.split "."
      new_ext = if new_filename_split.length <= 1 then "" else new_filename_split[new_filename_split.length-1]
      if new_ext != file_obj.ext
        new_filename += ".#{file_obj.ext}"

      @tasks_files.update file_id, 
        $set:
          name: new_filename

      return

  getFilesArchiveOfTask: (task_id, user_id) ->
    check task_id, String
    check user_id, String
    
    if not @isUserAllowedToAccessTasksFiles(task_id, user_id)
      throw @_error "access-denied"

    zip = new JSZip()
    has_files = false

    @tasks_files.find
      "meta.task_id": task_id
    .forEach (file) =>
      has_files = true
      gridfs_id = file.meta.gridfs_id

      if gridfs_id?
        filestream = @gfs.createReadStream
          _id: gridfs_id
        filestream.on "error", (err) ->
          throw err
        
        zip.file file.name, filestream,
          date: file.meta.upload_date
    
    if not has_files
      throw @_error "access-denied"

    task = @tasks_collection.findOne(task_id)

    if not task?
      throw @_error "access-denied"

    return {
      name: "justdo-task-#{task.seqId}-files-archive.zip"
      stream: zip.generateNodeStream()
    } 

  _setupFilesArchiveRoute: ->
    self = @
    Router.route "/justdo-files/files-archive/:task_id", ->
      task_id = @params.task_id

      # Authenicate user
      login_token = @request.cookies.meteor_login_token
      if login_token? and (user = Meteor.users.findOne({"services.resume.loginTokens.hashedToken" : Accounts._hashLoginToken(@request.cookies.meteor_login_token)}))?
        try
          files_archive = self.getFilesArchiveOfTask task_id, user._id
          @response.setHeader "Content-Disposition", "inline; filename=\"#{files_archive.name}\""
          files_archive.stream.pipe @response
        catch e
          if e.error == "access-denied"
            @response.statusCode = 403
            @response.end "Access denied!"
          else
            throw e
      else
        @response.statusCode = 403
        @response.end "Access denied!"

    , {where: "server"}

  uploadAndRegisterFile: (task_id, file_blob, filename, mimetype, metadata, user_id) ->
    file_opts =
      fileName: filename
      type: mimetype
      meta:
        source: "maildo"
        task_id: task_id
      userId: user_id

    fiber = Fiber.current
    if not (fiber = Fiber.current)?
      throw @_error "no-fiber"

    @tasks_files.write file_blob, file_opts, (err, file) ->
      fiber.run({err, file})

      return
    , true # true is for onAfterUpload to be called
    {err, file} = Fiber.yield()

    if err?
      throw err

    return_obj =
      _id: file._id
      title: file.name
      size: file.size
      type: file.type
      metadata: metadata
      user_uploaded: file.user_id
      date_uploaded: new Date()
      storage_type: "justdo-files"

    return return_obj

  removeUserAvatar: (options, user_id) ->
    check user_id, String

    if not (exclude = options?.exclude)?
      exclude = []

    if _.isString exclude
      exclude = [exclude]

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see AVATARS_COLLECTION_USERID_INDEX)
    #
    @avatars_collection.remove({_id: {$nin: exclude}, userId: user_id}, {multi: true})

    return
