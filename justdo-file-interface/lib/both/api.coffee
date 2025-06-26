_.extend JustdoFilesInterface.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @_registered_fs = {}
    @_default_fs_id = null

    @setupRouter()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  # Register a file system
  registerFsObjectSchema: new SimpleSchema JustdoFilesInterface.both_register_fs_options_schema_properties
  registerFs: (fs_id, fs_obj) ->
    if not fs_id?
      throw @_error "missing-argument", "File syystem ID is required"

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @registerFsObjectSchema,
        fs_obj,
        {throw_on_error: true}
      )
    fs_obj = cleaned_val  

    @_registered_fs[fs_id] = fs_obj
    
    @_setDefaultFsIdIfEmpty fs_id
      
    return
  
  _setDefaultFsIdIfEmpty: (fs_id) ->
    if _.isEmpty @_getDefaultFsId()
      @setDefaultFsId fs_id
      
    return

  setDefaultFsId: (fs_id) ->
    if not @_registered_fs[fs_id]?
      throw @_error "not-supported",  "File system '#{fs_id}' not found. Please register it first."

    if not _.isEmpty @_getDefaultFsId()

    @_default_fs_id = fs_id
    return
  
  _getDefaultFsId: ->
    return @_default_fs_id
  
  getDefaultFsId: ->
    if not @_getDefaultFsId()?
      throw @_error "not-supported", "No default file system has been set. Please set one first."

    return @_getDefaultFsId()
  

  # Connect to a file system and return connection object
  connect: (fs_id) ->
    if not fs_id?
      fs_id = @getDefaultFsId()
    
    if not (fs = @_registered_fs[fs_id])?
      throw @_error "not-supported", "File system \"#{fs_id}\" not found"

    return fs
