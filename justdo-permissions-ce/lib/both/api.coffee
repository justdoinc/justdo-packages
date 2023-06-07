_.extend JustdoPermissions.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return


  _isSkipPermissionsMode: -> JustdoHelpers.getFiberVar("ignore_justdo_permissions_scope") is true

  runCbInIgnoredPermissionsScope: (cb) ->
    return JustdoHelpers.runCbInFiberScope("ignore_justdo_permissions_scope", true, cb)

  registerPermissionsCategory: ->
    return

  registerTaskPermission: ->
    return

  registerJustdoPermission: ->
    return

  forcePermissionsCategoryDefaultTaskPermissionsValue: ->
    return

  forcePermissionsCategoryDefaultJustdoPermissionsValue: ->
    return

  forceDefaultPermissionsValue: ->
    return

  checkTaskPermissions: ->
    return true

  requireTaskPermissions: ->
    return

  checkJustdoPermissions: ->
    return true

  requireJustdoPermissions: ->
    return
