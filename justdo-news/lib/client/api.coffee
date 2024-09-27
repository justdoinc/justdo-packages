_.extend JustdoNews.prototype,
  _immediateInit: ->
    # Caches canonical i18n news paths with the following structure:
    # {
    #   ["/category/news_id"]:
    #     [lang1]: "/category/news_id--news-title-in-url",
    #     [lang2]: "pending",
    #     ...
    # }
    # Note: 
    # 1. To avoid requesting the same news path multiple times, it uses "pending" to indicate that the request is in progress.
    # 2. news_id is the _id of the news document, WITHOUT the title part (i.e. the part after "--")
    # 3. For now, it does not store the template part because it doesn't support title-in-url yet and hence can simply be concatenated.
    @_canonical_news_paths_with_title = {}
    @_canonical_news_paths_with_title_dep = new Tracker.Dependency()
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

  _requestAndCacheCanonicalNewsPathWithTitle: (category, news_id, lang) ->
    news_path = "/#{category}/#{news_id}"
    page_title = @getNewsPageTitle @getNewsByIdOrAlias(category, news_id).news_doc

    @newsTitleToUrlComponent page_title, lang, (err, title_component) =>
      if err?
        console.error err
        return

      @_canonical_news_paths_with_title[news_path][lang] = "#{news_path}#{title_component}"
      @_canonical_news_paths_with_title_dep.changed()

      return

    return

  _getCanonicalNewsPathWithTitle: (category, news_id, lang) ->
    @_canonical_news_paths_with_title_dep.depend()
    news_path = "/#{category}/#{news_id}"
    
    if (canonical_news_path = @_canonical_news_paths_with_title[news_path]?[lang])? and not (request_pending = canonical_news_path is "pending")
      return canonical_news_path
    
    if not request_pending
      # If the canonical news path is not cached, generate it
      if not @_canonical_news_paths_with_title[news_path]?
        @_canonical_news_paths_with_title[news_path] = {}
      @_canonical_news_paths_with_title[news_path][lang] = "pending"

      @_requestAndCacheCanonicalNewsPathWithTitle category, news_id, lang
    
    return news_path

  getCanonicalNewsPath: (options) ->
    {category, news, template, lang} = options
    if not lang?
      lang = APP.justdo_i18n.getLang()

    news_category_obj = @getCategory category

    if _.isString news
      news_doc = @getNewsByIdOrAlias(category, news).news_doc
    else
      news_doc = news
    news_id = news_doc._id

    news_path = "/#{category}/#{news_id}"

    if news_category_obj.title_in_url
      news_path = @_getCanonicalNewsPathWithTitle category, news_id, lang

    if (not _.isEmpty template) and (not @isDefaultNewsTemplate template)
      news_path = "#{news_path}/#{template}"
    
    return news_path