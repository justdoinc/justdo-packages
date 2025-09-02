_.extend JustdoFilesInterface.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @_registered_fs = {}
    @_default_fs_id = null
    if Meteor.isClient
      @_default_fs_id_dep = new Tracker.Dependency()

    @setupRouter()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return
  
  _validateOptionsWithRequiredProperties: (fs_id, fs_obj, required_properties) ->
    for key, type of required_properties
      if not (value = fs_obj[key])?
        throw @_error "missing-argument", "File system '#{fs_id}' is missing required property '#{key}'"

      if not value instanceof type
        throw @_error "invalid-argument", "File system '#{fs_id}' property '#{key}' must be a #{type.name}  instance"

  # Register a file system
  registerFs: (fs_id, fs_obj) ->
    if not fs_id?
      throw @_error "missing-argument", "File system ID is required"

    @_validateOptionsWithRequiredProperties fs_id, fs_obj, JustdoFilesInterface.both_register_fs_options_required_properties
    if Meteor.isClient
      @_validateOptionsWithRequiredProperties fs_id, fs_obj, JustdoFilesInterface.client_register_fs_options_required_properties
    if Meteor.isServer
      @_validateOptionsWithRequiredProperties fs_id, fs_obj, JustdoFilesInterface.server_register_fs_options_required_properties

    @_registered_fs[fs_id] = fs_obj
    @_setDefaultFsIdIfEmpty fs_id
      
    return
  
  isFsRegistered: (fs_id) ->
    return @_registered_fs[fs_id]?
  
  requireFsRegistered: (fs_id) ->
    if not @isFsRegistered(fs_id)
      throw @_error "not-supported",  "File system '#{fs_id}' not found. Please register it first."

    return
  
  _getFs: (fs_id) ->
    fs_id = fs_id or @_getDefaultFsId()
    @requireFsRegistered fs_id
    return @_registered_fs[fs_id]

  _setDefaultFsIdIfEmpty: (fs_id) ->
    if _.isEmpty @_getDefaultFsId()
      @setDefaultFsId fs_id
      
    return

  setDefaultFsId: (fs_id) ->
    @requireFsRegistered fs_id

    @_default_fs_id = fs_id

    if Meteor.isClient
      @_default_fs_id_dep.changed()

    return
  
  _getDefaultFsId: ->
    return @_default_fs_id
  
  getDefaultFsId: ->
    if Meteor.isClient
      @_default_fs_id_dep.depend()

    return @_getDefaultFsId()
  
  cloneWithForcedFs: (fs_id) ->
    # Create a new obj that inherits from the current obj that sets the
    # _default_filesystem to be the file_system arg provided.

    cloned_obj = Object.create @
    cloned_obj.setDefaultFsId fs_id

    return cloned_obj

  getFileSizeLimit: (fs_id) ->
    fs = @_getFs fs_id

    return fs.getFileSizeLimit()

  getFileLink: (fs_id, options) ->
    fs = @_getFs fs_id

    return fs.getFileLink options
  
  _ensureFileObjsAreNormalized: (fs_id, files) ->
    required_properties = ["_id", "type", "name", "size", "uploaded_by", "uploaded_at"]
    missing_properties = []

    # Ensure that the returned file objects are normalized to the same properties
    file_with_missing_properties = _.find files, (file) ->
      missing_properties = _.difference required_properties, _.keys(file)
      return not _.isEmpty missing_properties

    if file_with_missing_properties?
      throw @_error "not-supported", "getFilesByIds: When called with fs_id \"#{fs_id}\", the returned file objects are missing the following properties: #{missing_properties.join(", ")}.\nThis would likely cause integration errors with other packages. Please normalize the files objects before returning them."
    
    return
  
  getFilesByIds: (fs_id, file_ids) ->
    # Important: This method return file objects with mostly metadata fields. The field names are normalized to be consistent across file systems.
    # This is meant to facilitate usecases like showing a list of files.
    # Since the field names are normalized, it is discouraged to use this method in other file system methods (e.g. isFileExists)
    fs = @_getFs fs_id

    if _.isString(file_ids)
      file_ids = [file_ids]
    
    files = fs.getFilesByIds file_ids

    @_ensureFileObjsAreNormalized fs_id, files

    return files

  isFileExists: (fs_id, options) ->
    fs = @_getFs fs_id

    return fs.isFileExists options
  
  isFileTypePreviewable: (fs_id, file_type) ->
    fs = @_getFs fs_id

    return fs.isFileTypePreviewable file_type
  
  getFileCategory: (file_type) ->
    if not _.isString(file_type)
      throw @_error "invalid-argument", "File type must be a string"
    
    file_type = file_type.toLowerCase()

    if file_type.indexOf "image/" is 0
      return "image"

    if file_type.indexOf "video/" is 0
      return "video"
      
    if file_type.indexOf "application/pdf" is 0
      return "pdf"

    return "other"
  
  isUserAllowedToUploadTaskFile: (fs_id, task_id, user_id) ->
    fs = @_getFs fs_id

    return fs.isUserAllowedToUploadTaskFile task_id, user_id