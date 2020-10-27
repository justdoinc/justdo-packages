_.extend JustdoHelpers,
  deepStructureObjectKeysTraverse = (structure, cb) ->
    # Traverse structure, for every object key found, calls cb with it. 
    if _.isArray(structure)
      for item in structure
        deepStructureObjectKeysTraverse(item, cb)
    else if _.isObject(structure)
      for key, val of structure
        cb(key)
        
        if _.isObject(val)
          deepStructureObjectKeysTraverse(val, cb)
          
    return