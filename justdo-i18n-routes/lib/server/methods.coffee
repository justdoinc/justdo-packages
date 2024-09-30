_.extend JustdoI18nRoutes.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods 
      getI18nPathFromRouteOptions: (path, lang) ->
        check path, String
        check lang, String

        return self.i18nPath path, lang

    return