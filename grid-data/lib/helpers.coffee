share.helpers =
  getCollectionMethodName: (collection, method_name) -> "#{collection._name}_#{method_name}"

  getCollectionPubSubName: (collection) -> "#{collection._name}_grid"

  getPathArray: (path) -> path.replace(/(^\/|\/$)/g, "").split("/")

  getPathItemId: (path) -> _.last share.helpers.getPathArray path

  getPathParentId: (path) ->
    path_array = share.helpers.getPathArray "/0#{path}"

    if path_array.length < 2
      return null
    else
      return path_array[path_array.length - 2]
