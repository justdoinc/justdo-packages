_.extend JustdoNews.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  getActiveCategetoryByRootPath: ->
    return Router?.current()?.route?._path?.match(JustdoNews.root_path_regex)?[0]?.replace "/", ""

  getNewsIdIfExists: (category, news_id_or_alias) ->
    news_doc = @getNewsByIdOrAlias category, news_id_or_alias
    return news_doc?._id

  getNewsTemplateIfExists: (category, news_id_or_alias, template_name) ->
    if not (news = @getNewsByIdOrAlias category, news_id_or_alias)
      return
    return _.find news.templates, (template_obj) -> template_obj._id is template_name

  redirectToMostRecentNewsPageByCategoryOrFallback: (category) ->
    if not (most_recent_news_id_under_cat = @getMostRecentNewsIdUnderCategory category)?
      throw @_error "news-category-not-found"
    Router.current().redirect "/#{category}/#{most_recent_news_id_under_cat}"
    return
