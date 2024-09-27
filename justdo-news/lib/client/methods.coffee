_.extend JustdoNews.prototype, 
  newsTitleToUrlComponent: (title, lang, cb) ->
    if _.isEmpty lang
      lang = APP.justdo_i18n.getLang()

    return Meteor.call "newsTitleToUrlComponent", title, lang, cb