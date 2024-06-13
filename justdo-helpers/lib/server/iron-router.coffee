_.extend JustdoHelpers,
  # This method is a re-implementation of Iron Router's findFirstRoute.
  # Aside from adding the capability of getting original path from an i18n path,
  # the only difference is that Iron Router's implementation will also match the current environment (server/client),
  # which makes server-side calls to this method return null.
  getRouteNameFromPath: (path) ->
    if APP.justdo_i18n_routes?
      path = APP.justdo_i18n_routes.getPathWithoutLangPrefix path
    
    for route_path, route_def of Router.routes._byPath
      if route_def.handler.test path
        return route_def.getName()
    
    return null