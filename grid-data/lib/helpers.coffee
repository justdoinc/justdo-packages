share.helpers = helpers =
  getCollectionMethodName: (collection, method_name) -> "#{collection._name}_#{method_name}"

  getCollectionPubSubName: (collection) -> "#{collection._name}_grid"

  normalizePath: (path) -> if _.last(path) != "/" then "#{path}/" else path

  isRootPath: (path) -> helpers.normalizePath(path) == "/"

  getPathArray: (path) ->
    if helpers.isRootPath(path)
      return []

    helpers.normalizePath(path).replace(/(^\/|\/$)/g, "").split("/")

  getParentPath: (path) -> helpers.normalizePath(path).replace(/[^\/]+\/$/, "")

  getAllAncestorPaths: (path) ->
    # Return all ancestor paths including path itself
    path_array = helpers.getPathArray(path)
    current_path = "/"
    ancestors = []
    for item_id in path_array
      ancestors.push current_path += "#{item_id}/"

    ancestors

  getPathItemId: (path) -> _.last helpers.getPathArray helpers.normalizePath(path)

  getPathParentId: (path) ->
    path_array = helpers.getPathArray "/0#{helpers.normalizePath(path)}"

    if path_array.length < 2
      return null
    else
      return path_array[path_array.length - 2]