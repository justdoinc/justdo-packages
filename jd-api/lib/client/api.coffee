_.extend JD,
  activeJustdo: (fields, options) ->
    if not fields?
      if options?.allow_undefined_fields == true
        fields = undefined
      else
        throw new Meteor.Error "fields-not-specified", "Fields parameters must be provide"
    if (active_obj = APP.modules?.project_page?.curProj()?.getProjectDoc({fields: fields}))?
      return active_obj

    # Normalize non-existence result to 'undefined'
    return undefined

  activeJustdoId: ->
    return @activeJustdo({_id: 1})?._id

  active_justdo:
    isAdmin: ->
      if not (cur_proj = APP.modules?.project_page?.curProj())?
        return false

      return cur_proj.isAdmin()

  activeItemId: ->
    if not (active_item_id = APP.modules.project_page.activeItemId())?
      return null

    if not APP.collections.Tasks.findOne(active_item_id, {fields: {_id: 1}})?
      return null

    return active_item_id

  activeItem: (fields, options) ->
    if not fields?
      if options?.allow_undefined_fields == true
        fields = undefined
      else
        throw new Meteor.Error "fields-not-specified", "The fields argument must be provided"
    if (active_obj = APP.modules?.project_page?.activeItemObj(fields, false))? # false, is to avoid using the grid data structure, to ensure we'll have reactivity for the selected fields.
                                                                               # Further, when an item is removed the grid data structure might update
                                                                               # few ticks later, which can a pitfall for developers.
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

  activeItemUsers: -> _.uniq(JD.activeItemAugmentedFields({users: 1})?.users or [])

  activePath: ->
    if (active_path = APP.modules?.project_page?.activeItemPath())?
      return active_path

    # Normalize non-existence result to 'undefined'
    return undefined

  registerPlaceholderItem: (...args) -> APP.modules?.main?.registerPlaceholderItem?.apply(APP.modules?.main, args)

  unregisterPlaceholderItem: (...args) -> APP.modules?.main?.unregisterPlaceholderItem?.apply(APP.modules?.main, args)

  getPlaceholderItems: (...args) -> APP.modules?.main?.getPlaceholderItems?.apply(APP.modules?.main, args)