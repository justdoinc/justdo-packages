_.extend JustdoHelpers,
  currentPageName: ->
    if not (current_route = Router.current())?
      return null

    if current_route._handled
      return current_route.route.getName()
    else
      return "404"

    return