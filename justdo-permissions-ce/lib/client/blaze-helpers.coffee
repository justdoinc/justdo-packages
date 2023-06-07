if (templating = Package.templating)?
  {Template} = templating

  Template.registerHelper "checkTaskPermissions", (permissions, tasks) ->
    permissions = permissions.split(",")
    tasks = tasks.split(",")

    return APP.justdo_permissions.checkTaskPermissions(permissions, tasks)

  Template.registerHelper "checkCurrentTaskPermissions", (permissions) ->
    permissions = permissions.split(",")

    if (item_id = JD.activeItemId())?
      return APP.justdo_permissions.checkTaskPermissions(permissions, item_id)

    return false

  Template.registerHelper "checkJustdoPermissions", (permissions, justdo_id) ->
    permissions = permissions.split(",")

    if not _.isString(justdo_id)
      justdo_id = undefined

    return APP.justdo_permissions.checkJustdoPermissions(permissions, justdo_id)

  Template.registerHelper "checkCurrentJustdoPermissions", (permissions) ->
    permissions = permissions.split(",")

    if (justdo_id = JD.activeJustdoId())?
      return APP.justdo_permissions.checkJustdoPermissions(permissions, justdo_id)

    return false
