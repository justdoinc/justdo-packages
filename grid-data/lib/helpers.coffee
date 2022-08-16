share.helpers = helpers =
  getCollectionMethodName: (collection, method_name) -> "#{collection._name}_#{method_name}"

  getCollectionPubSubName: (collection) -> "#{collection._name}_grid"

  getCollectionUnmergedPubSubName: (collection) -> "#{collection._name}_grid_um"

  normalizePath: (path) -> if _.last(path) != "/" then "#{path}/" else path

  isRootPath: (path) -> path == "/"

  getPathArray: (path) ->
    if helpers.isRootPath(path)
      return []

    path.replace(/(^\/|\/$)/g, "").split("/")

  getParentPath: (path) -> path.replace(/[^\/]+\/$/, "")

  getAllAncestorPaths: (path) ->
    # Return all ancestor paths including path itself
    path_array = helpers.getPathArray(path)
    current_path = "/"
    ancestors = []
    for item_id in path_array
      ancestors.push current_path += "#{item_id}/"

    ancestors

  getPathItemId_: (path) -> _.last helpers.getPathArray path

  getPathItemId: (path) -> path.substring(path.lastIndexOf("/", path.length - 2) + 1, path.length - 1)

  getPathParentId: (path) ->
    path_array = helpers.getPathArray "/0#{path}"

    if path_array.length < 2
      return null
    else
      return path_array[path_array.length - 2]

  getPathLevel: (path) ->
    JustdoHelpers.substrCount(path, "/") - 2 # - 2 is for the first and last /

  getAllSubPaths: (path) ->
    # Doesn't return root
    path_array = @getPathArray(path)

    last = "/"
    sub_paths = []
    for item in path_array
      sub_paths.push (last += item + "/")

    return sub_paths

  joinPathArray: (path_array) ->
    joined = path_array.join('/')
    return if joined.length > 0 then "/#{joined}/" else "/"

  callCb: JustdoHelpers.callCb

  non_user_editable_columns_allowed_over_the_wire: ["updatedAt"]

  isFieldDefUserEditable: (field_id, field_def, allow_exceptions=false) ->
    # allow_exceptions is to allow exceptions for some fields that their autoVal definition is too complex,
    # and it was decided to allow them to be received over the wire by the server even though they are not
    # really user editable (the value received is later-on ignored, their autoVal code wasn't fixed to reduce
    # the chance of introducing new bugs for a very long-standing, working, code)
    if allow_exceptions is true
      if field_id in helpers.non_user_editable_columns_allowed_over_the_wire
        return true

    # field_def.user_editable_column, if unset, considered same as `grid_editable_column`, this function
    # implements the fallback.
    #
    # See more details under grid-control/lib/both/simple_schema_extensions.coffee
    if field_def.client_only
      return false

    if field_def.user_editable_column is false
      return false

    if field_def.user_editable_column isnt true
      # If user_editable_column is true, we always allow copy, otherwise, since we checked
      # already that it isn't false above, it is undefined, which means we need to fallback to 
      # grid_editable_column
      if field_def.grid_editable_column is false
        return false

    return true