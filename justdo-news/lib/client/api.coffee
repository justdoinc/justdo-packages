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

  redirectToMostRecentNewsPageByCategoryOrFallback: (category) ->
    if not (news_doc = @getMostRecentNewsObjUnderCategory category)?
      throw @_error "news-category-not-found"

    url = @getI18nCanonicalNewsPath {category, news: news_doc}
    url = APP.justdo_i18n_routes?.i18nPath(url) or url

    Router.current().redirect url
    return
