_.extend JustdoI18nRoutes.prototype, 
  getI18nPathFromRouteOptions: (path, lang, cb) ->
    return Meteor.call "getI18nPathFromRouteOptions", path, lang, cb