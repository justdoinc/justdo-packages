import Grid from "gridfs-stream"
import fs from "fs"
import { MongoInternals } from "meteor/mongo"

_.extend JustdoFiles.prototype,
  _immediateInit: ->
    @_setupOstrioFiles()
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  performInstallProcedures: (project_doc, user_id) ->
    # Called when plugin installed for project project_doc._id
    console.log "Plugin #{JustdoFormulaFields.project_custom_feature_id} installed on project #{project_doc._id}"

    return

  performUninstallProcedures: (project_doc, user_id) ->
    # Called when plugin uninstalled from project project_doc._id

    # Note, isn't called on project removal

    console.log "Plugin #{JustdoFormulaFields.project_custom_feature_id} removed from project #{project_doc._id}"

    return

  _setupOstrioFiles: ->
    TaskFiles = @tasks_files

    gfs = Grid MongoInternals.defaultRemoteCollectionDriver().mongo.db, MongoInternals.NpmModule

    TaskFiles.onAfterUpload = (file) ->
      console.log "Received file: "
      console.log file
      console.log "Saving to mongodb..."

      writestream = gfs.createWriteStream
        filename: file.name
        content_type: file.mime
      (fs.createReadStream file.path).pipe writestream
      writestream.on "close", Meteor.bindEnvironment (gridfs_file) ->
        @collection.update gridfs_file._id,
          $set:
            "meta.gridfs_id": gridfs_file._id.toString()
        @unlink @collection.findOne file._id # Remove the temporary file
        console.log "Saved file to mongodb"

    TaskFiles.interceptDownload = (http, file, versionName) ->
      console.log "User trying to download the file"
      # XXX check if user is allowed to donwload the file
      gridfs_id = file.meta.gridfs_id
      if gridfs_id?
        readstream = gfs.createReadStream
          _id: gridfs_id
        readstream.on "error", (err) ->
          throw err
        readstream.pipe http.response
      return Boolean gridfs_id
