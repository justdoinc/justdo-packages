Template.support_page.onCreated ->
  tpl = @

  @active_article_rv = new ReactiveVar(null)
  @getActiveArticle = ->
    return tpl.active_article_rv.get()
  @setActiveArticle = (article_id) ->
    tpl.active_article_rv.set article_id
    return

  @active_tag_rv = new ReactiveVar(share.default_tag)
  @getActiveTag = ->
    return tpl.active_tag_rv.get()
  @setActiveTag = (tag_id) ->
    tpl.active_tag_rv.set tag_id
    return
    
  @autorun =>
    # This autorun is used to
    # - set the active article based on the news_id in the url
    # - set the active tag based on the hash in the url
    if not (router = Router.current())?
      return

    params = router.getParams()

    if (article_id = params?.news_id)?
      if APP.justdo_seo?
        article_id = APP.justdo_seo.getPathWithoutHumanReadableParts article_id
      tpl.setActiveArticle article_id

    if (hash = router.getParams().hash)? and (tag = share.supported_tags.find((t) -> t._id is hash))?
      tpl.setActiveTag tag._id

    Tracker.afterFlush ->
      window.scrollTo 0, 0

    return

  @search_query_rv = new ReactiveVar("")
  @setSearchQuery = ->
    query = $(".support-input").val()?.trim()
    tpl.search_query_rv.set query
    return
  @clearSearchQuery = ->
    tpl.search_query_rv.set ""
    $(".support-input").val("")
    return
  @getSearchQuery = ->
    return tpl.search_query_rv.get()

  @autorun =>
    # For reactivity. We want to clear the search query when the active article changes.
    @getActiveArticle()
    @clearSearchQuery()
    return

  return

Template.support_page.helpers
  parentTpl: ->
    return Template.instance()

  activeArticle: ->
    tpl = Template.instance()
    return tpl.getActiveArticle()

  getActiveArticle: ->
    tpl = Template.instance()
    return tpl.getActiveArticle
  
  setActiveArticle: ->
    tpl = Template.instance()
    return tpl.setActiveArticle

  getArticleMainTemplate: ->
    main_template = _.find @templates, (template) -> template._id is JustdoNews.default_news_template
    return main_template?.template_name

  tags: ->
    return share.supported_tags

  getHashFragment: ->
    hash_fragment = "#"

    if @_id isnt share.default_tag
      hash_fragment += @_id

    return hash_fragment

  getActiveTag: ->
    tpl = Template.instance()
    return tpl.getActiveTag

  setActiveTag: ->
    tpl = Template.instance()
    return tpl.setActiveTag

  getSearchQuery: ->
    tpl = Template.instance()
    return tpl.getSearchQuery

  tagIsActive: ->
    if Template.instance().getActiveTag() is @_id
      return "active"

Template.support_page.events
  "click .support-tag": (e, tpl) ->
    active_tag = e.currentTarget.id
    tpl.setActiveTag active_tag

    window.scrollTo
      top: 0
      behavior: "smooth"

    return

  "click .support-input-search-btn": (e, tpl) ->
    tpl.setSearchQuery()

    return

  "keyup .support-input": (e, tpl) ->
    tpl.setSearchQuery()
    
    return
