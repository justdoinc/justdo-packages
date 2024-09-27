_.extend JustdoNews.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods 
      newsTitleToUrlComponent: (title, lang) ->
        check title, Match.Maybe String
        check lang, Match.Maybe String

        return self.newsTitleToUrlComponent title, lang

    return