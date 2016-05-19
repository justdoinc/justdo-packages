share.helpers = helpers =
  getCollectionMethodName: (collection, method_name) -> "#{collection._name}_#{method_name}"

  getCollectionPubSubName: (collection) -> "#{collection._name}_grid"

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

  joinPathArray: (path_array) -> "/#{path_array.join('/')}/"

  callCb: JustdoHelpers.callCb