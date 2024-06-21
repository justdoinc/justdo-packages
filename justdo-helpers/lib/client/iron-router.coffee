_.extend JustdoHelpers,
  currentPageName: ->
    if not (current_route = Router.current())?
      return null

    if current_route._handled
      return current_route.route.getName()
    else
      return "404"

    return
  
  # This method is to allow both client and server to get route name from path using the same api from justdo helpers.
  # Check the server-side implementation (/server/iron-router.coffee) for more details.
  getRouteNameFromPath: (url) -> Router.findFirstRoute(url)?.getName()