symbols_regex = /^[a-z0-9-]+$/

permission_condition_schema = new SimpleSchema
  condition:
    type: String

    allowedValues: -> _.union(_.keys(JustdoPermissions.justdos_conditions_types), _.keys(JustdoPermissions.tasks_conditions_types))

  options:
    type: Object

    optional: true

    blackbox: true

  pass_if_applied_to_self: # If set to false, we will regard the condition as not applying to the target task.
                           #
                           # We will regard the test as passing only if it is passing for the ancestors.
                           #
                           # In that sense, if this one is false and pass_if_applied_to_ancestor is false
                           # or pass_if_applied_to_ancestor_max_level is set to 0, the condition will fail for
                           # sure.
                           #
                           # Ignored for JustDo conditions
    type: Boolean

    optional: true

    defaultValue: true

  pass_if_applied_to_ancestor: # If set to true, if the condition test passes for any ancestor
                               # of the task, we'll regard the condition as met, and grant the
                               # permission, even if the condition fails for the task itself.
                               #
                               # Ignored for JustDo conditions
    type: Boolean

    optional: true

    defaultValue: false

  pass_if_applied_to_ancestor_max_level: # If set to null we don't limit the levels of ancestors.
                                         #
                                         # If set to 0 pass_if_applied_to_ancestor is treated as false.
                                         #
                                         # If set to a positive integer, we will limit how many levels of
                                         # ancestors we'll look back to, to try to find an ancestor to
                                         # which the condition is applied (if such an ancestor to which
                                         # the condition is applied will be found, we'll regard the
                                         # condition as passing the test, and grant the permission).
                                         #
                                         # Ignored for JustDo conditions
    type: Number

    optional: true

    defaultValue: null

permission_value_schema = [permission_condition_schema]

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

  registerPermissionsCategory: (permissions_category_id, conf) ->
    return

  registerTaskPermission: (permission, conf) ->
    return

  registerJustdoPermission: (permission, conf) ->
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
    return

  requireJustdoPermissions: ->
    return
