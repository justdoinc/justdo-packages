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
  getActiveCategetoryByRootPath: ->
    return Router?.current()?.route?._path?.match(JustdoNews.root_path_regex)?[0]?.replace "/", ""

  getAllNewsByCategory: (category) ->
    @category_dep.depend()
    @news_dep.depend()
    if _.has @news, category
      return JSON.parse(JSON.stringify(@news[category]))
    return []

  getNewsByIdOrAlias: (category, news_id_or_alias) ->
    @category_dep.depend()
    @news_dep.depend()
    return _.find @news[category], (news) -> (news._id is news_id_or_alias) or (news_id_or_alias in news.aliases)

  getMostRecentNewsUnderCategory: (category) ->
    @category_dep.depend()
    @news_dep.depend()
    return@news[category]?[0]?._id

  getNewsIdIfExists: (category, news_id_or_alias) ->
    news_doc = @getNewsByIdOrAlias category, news_id_or_alias
    return news_doc?._id

  getTemplateForNewsIfExists: (category, news_id_or_alias, template_name) ->
    if not (news = @getNewsByIdOrAlias category, news_id_or_alias)
      return
    return _.find news.templates, (template_obj) -> template_obj._id is template_name

  redirectToMostRecentNewsPageByCategoryOrFallback: (category) ->
    if not _.isString category
      category = JustdoNews.default_news_category
    Router.current().redirect "/#{category}/#{@getMostRecentNewsUnderCategory category}"
