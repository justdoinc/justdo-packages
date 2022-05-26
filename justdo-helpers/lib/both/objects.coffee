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
  
  objectDeepInherit: (o) ->
    o = Object.create(o)

    for key, val of o
      if val? and typeof val == "object"
        o[key] = JustdoHelpers.objectDeepInherit(val)
      else
        o[key] = val

    return o
  
  eqSets: (set_a, set_b) ->
    if set_a.size != set_b.size
      return false
    
    iterator = set_a.entries()
    
    while not (entry = iterator.next()).done
      if not set_b.has(entry.value[0])
        return false
    
    return true
    
