_.extend JD,
  activeJustdo: (fields) ->
    if (active_obj = APP.modules?.project_page?.curProj()?.getProjectDoc({fields: fields}))?
      return active_obj

    # Normalize non-existence result to 'undefined'
    return undefined

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

  activePath: ->
    if (active_path = APP.modules?.project_page?.activeItemPath())?
      return active_path

    # Normalize non-existence result to 'undefined'
    return undefined

  registerPlaceholderItem: (...args) -> APP.modules.main.registerPlaceholderItem.apply(APP.modules.main, args)

  unregisterPlaceholderItem: (...args) -> APP.modules.main.unregisterPlaceholderItem.apply(APP.modules.main, args)

  getPlaceholderItems: (...args) -> APP.modules.main.getPlaceholderItems.apply(APP.modules.main, args)