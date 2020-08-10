_.extend JD,
  activeJustdo: (fields) ->
    if not fields
      throw new Meteor.Error "fields parameter must be provided"
    if fields == "all-fields"
      fields = undefined
    if (active_obj = APP.modules?.project_page?.curProj()?.getProjectDoc({fields: fields}))?
      return active_obj

    # Normalize non-existence result to 'undefined'
    return undefined

  activeJustdoId: ->
    return @activeJustdo({_id: 1})._id
    
  active_justdo:
    isAdmin: ->
      if not (cur_proj = APP.modules?.project_page?.curProj())?
        return false

      return cur_proj.isAdmin()

  activeItemId: ->
    return APP.modules.project_page.activeItemId()

  activeItem: (fields) ->
    if (active_obj = APP.modules?.project_page?.activeItemObj(fields))?
      return active_obj

    # Normalize non-existence result to 'undefined'
    return undefined

  subscribeItemsAugmentedFields: (items_ids_array, fetched_fields_arr, options, cb) ->
    return APP.projects.subscribeTasksAugmentedFields(items_ids_array, fetched_fields_arr, options, cb)

  subscribeActiveItemAugmentedFields: (fetched_fields_arr, cb) ->
    return APP.projects.subscribeActiveTaskAugmentedFields(fetched_fields_arr, cb)

  activeItemAugmentedFields: (fields) ->
    if not (active_item_id = JD.activeItemId())?
      return undefined

    return APP.collections.TasksAugmentedFields.findOne(active_item_id, {fields: fields})

  activeItemUsers: -> JD.activeItemAugmentedFields({users: 1})?.users or []

  activePath: ->
    if (active_path = APP.modules?.project_page?.activeItemPath())?
      return active_path

    # Normalize non-existence result to 'undefined'
    return undefined

  registerPlaceholderItem: (...args) -> APP.modules.main.registerPlaceholderItem.apply(APP.modules.main, args)

  unregisterPlaceholderItem: (...args) -> APP.modules.main.unregisterPlaceholderItem.apply(APP.modules.main, args)

  getPlaceholderItems: (...args) -> APP.modules.main.getPlaceholderItems.apply(APP.modules.main, args)