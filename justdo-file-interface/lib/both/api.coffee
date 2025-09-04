_.extend JustdoFileInterface.prototype,
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
  registerFs: (fs_id, options) ->
    if not fs_id?
      throw @_error "missing-argument", "File system ID is required"
    
    fs_obj = Object.create(JustdoFileInterface.FileSystemPrototype)
    _.extend fs_obj, options
    fs_obj.fs_id = fs_id

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

    return
  
  _getDefaultFsId: ->
    return @_default_fs_id
  
  getDefaultFsId: ->
    return @_getDefaultFsId()
  
  cloneWithForcedFs: (fs_id) ->
    # Create a new obj that inherits from the current obj that sets the
    # _default_filesystem to be the file_system arg provided.

    cloned_obj = Object.create @
    cloned_obj.setDefaultFsId fs_id

    return cloned_obj
