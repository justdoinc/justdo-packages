_.extend JD,
  activeJustdo: (fields) ->
    if (active_obj = APP.modules?.project_page?.curProj()?.getProjectDoc({fields: fields}))?
      return active_obj

    # Normalize non-existence result to 'undefined'
    return undefined

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