_.extend JustdoHelpers,
  deepStructureObjectKeysTraverse = (structure, cb) ->
    # Traverse structure, for every object key found, calls cb with it. 
    if _.isArray(structure)
      for item in structure
        deepStructureObjectKeysTraverse(item, cb)
    else if _.isObject(structure)
      for own key, value of structure
        cb(key)
        
        if _.isObject(value)
          deepStructureObjectKeysTraverse(value, cb)
          
    return