_invalidate_once_ids_become_exist_db = {}

_.extend JustdoHelpers,
  getCollectionIdMap: (collection) ->
    return collection._collection._docs

  getCollectionIdentifier: (collection) ->
    if (name = collection._name)?
      return name

    if not (_anon_collection_id = collection._anon_collection_id)?
      collection._anon_collection_id = Random.id()
    
    return collection._anon_collection_id

  nonReactiveIdExists: (collection, id) ->
    id_map_map = JustdoHelpers.getCollectionIdMap(collection)._map

    return id of id_map_map

  nonReactiveFullDocFindOneById: (collection, id, get_docs_by_reference) ->
    id_map_map = JustdoHelpers.getCollectionIdMap(collection)._map

    if id of id_map_map and typeof id_map_map[id] == "object"
      if not get_docs_by_reference? or not get_docs_by_reference
        return JustdoHelpers.objectDeepInherit(id_map_map[id])
      else
        return id_map_map[id]

    return undefined

  nonReactiveFullDocFindById: (collection, ids_array, options) ->
    ret_type = "array"
    if options?.ret_type == "object"
      ret_type = "object"

    limit = 0
    if options?.limit?
      limit = options.limit

    break_if_consecutive_missing_ids_count = 0
    if options?.break_if_consecutive_missing_ids_count?
      break_if_consecutive_missing_ids_count = options.break_if_consecutive_missing_ids_count

    get_docs_by_reference = false
    if options?.get_docs_by_reference?
      get_docs_by_reference = options.get_docs_by_reference

    if ret_type == "array"
      ret = []
    else if ret_type == "object"
      ret = {}
    else
      throw new Error "Unknown ret_type #{ret_type}"

    missing_ids = []

    items_found = 0
    consecutive_missing_ids_count = 0

    for id in ids_array
      if not (doc = JustdoHelpers.nonReactiveFullDocFindOneById(collection, id, get_docs_by_reference))?
        consecutive_missing_ids_count += 1

        missing_ids.push id

        if break_if_consecutive_missing_ids_count == consecutive_missing_ids_count
          break
      else
        consecutive_missing_ids_count = 0

        if ret_type == "array"
          ret.push doc
        else if ret_type == "object"
          ret[id] = doc

        items_found += 1

        if items_found == limit
          break

    return [ret, missing_ids]

  invalidateOnceIdsBecomeExist: (collection, missing_ids) ->
    if not Tracker.currentComputation?
      # We aren't inside a computation, just return
      return

    tracked_ids = {}

    for missing_id in missing_ids
      if not JustdoHelpers.nonReactiveIdExists(collection, missing_id)
        tracked_ids[missing_id] = true

    if _.isEmpty(tracked_ids)
      # Nothing to look for...
      return

    col_id = JustdoHelpers.getCollectionIdentifier(collection)

    if not (collection_watchers_construct = _invalidate_once_ids_become_exist_db[col_id])?
      collection_watchers_construct = 
        events_hooks:
          "after-set": (id, value) ->
            for watcher_id, watcher_def of collection_watchers_construct.tracked_ids_watchers
              if id of watcher_def.tracked_ids
                watcher_def.dep.changed()

            return

          "after-bulkSet": (docs) ->
            # Upon bulkSet just mark all as changed
            for watcher_id, watcher_def of collection_watchers_construct.tracked_ids_watchers
              watcher_def.dep.changed()

            return

        tracked_ids_watchers: {}

        tracked_ids_watchers_registered: -1

      _invalidate_once_ids_become_exist_db[col_id] = collection_watchers_construct

      for hook_id, hook of collection_watchers_construct.events_hooks
        JustdoHelpers.getCollectionIdMap(collection).on hook_id, collection_watchers_construct.events_hooks[hook_id]

    watcher_id = (collection_watchers_construct.tracked_ids_watchers_registered += 1)

    dep = new Tracker.Dependency()
    dep.depend()

    collection_watchers_construct.tracked_ids_watchers[watcher_id] =
      tracked_ids: tracked_ids
      dep: dep
    
    Tracker.onInvalidate ->
      delete collection_watchers_construct.tracked_ids_watchers[watcher_id]

      if _.isEmpty(collection_watchers_construct.tracked_ids_watchers)
        for hook_id, hook of collection_watchers_construct.events_hooks
          JustdoHelpers.getCollectionIdMap(collection).off hook_id, collection_watchers_construct.events_hooks[hook_id]

        delete _invalidate_once_ids_become_exist_db[col_id]
      
      return

    return
