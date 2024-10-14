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
    if not (news_doc = @getMostRecentNewsObjUnderCategory category)?
      throw @_error "news-category-not-found"

    url = "/#{category}/#{news_doc._id}"
    url = APP.justdo_i18n_routes?.i18nPathAndHrp(url) or url

    Router.go url, {}, {replaceState: true}
    return
