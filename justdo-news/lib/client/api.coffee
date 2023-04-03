_.extend JustdoNews.prototype,
  _immediateInit: ->
    @news = []
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  registerNews: (news_obj) ->
    @news.push news_obj
    @news = _.sortBy(@news, "date").reverse() # Ensures the first element is the newest
    return

  getAllNews: -> JSON.parse(JSON.stringify(@news))

    return _.find @news, (news) -> (news._id is version) or (news.title is version) or (version in news.aliases)
  getNewsByIdOrAlias: (news_id_or_alias) ->

  getMostRecentNews: -> @news[0]?._id

  getNewsIdIfExists: (news_id_or_alias) ->
    news_doc = @getNewsByIdOrAlias news_id_or_alias
    return news_doc?._id

  getTemplateForNewsIfExists: (news_id_or_alias, template_name) ->
    if not (news = @getNewsByIdOrAlias news_id_or_alias)
      return
    return _.find news.templates, (template_obj) -> template_obj._id is template_name

  redirectToMostRecentNewsPage: -> Router.current().redirect "/news/#{@getMostRecentNews()}"
