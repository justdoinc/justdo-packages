_.extend JustdoNews.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  getActiveCategetoryByRootPath: ->
    cur_path = APP.justdo_i18n_routes?.getCurrentPathWithoutLangPrefix() or Router?.current()?.route?._path
    if not cur_path?
      return
      
    return cur_path.match(JustdoNews.root_path_regex)?[0]?.replace "/", ""

  getNewsIdIfExists: (category, news_id_or_alias) ->
    news_doc = @getNewsByIdOrAlias(category, news_id_or_alias)?.news_doc
    return news_doc?._id

  redirectToMostRecentNewsPageByCategoryOrFallback: (category) ->
    if not (most_recent_news_id_under_cat = @getMostRecentNewsIdUnderCategory category)?
      throw @_error "news-category-not-found"

    url = "/#{category}/#{most_recent_news_id_under_cat}"
    url = APP.justdo_i18n_routes?.i18nPath(url) or url

    Router.current().redirect url
    return
