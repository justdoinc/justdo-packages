Template.support_page.onCreated ->
  @active_article_rv = new ReactiveVar(null)
  @active_tag_rv = new ReactiveVar(share.default_tag)
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
      @active_article_rv.set article_id

    if (hash = router.getParams().hash)? and (tag = share.supported_tags.find((t) -> t._id is hash))?
      @active_tag_rv.set tag._id

    Tracker.afterFlush ->
      window.scrollTo 0, 0

    return

  return

Template.support_page.helpers
  activeArticle: ->
    tpl = Template.instance()
    return tpl.active_article_rv.get()

  activeArticleRv: ->
    tpl = Template.instance()
    return tpl.active_article_rv

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

  activeTag: ->
    tpl = Template.instance()
    return tpl.active_tag_rv

  tagIsActive: ->
    if Template.instance().active_tag_rv.get() == @_id
      return "active"

Template.support_page.events
  "click .support-tag": (e, tpl) ->
    active_tag = e.currentTarget.id
    tpl.active_tag_rv.set active_tag

    window.scrollTo
      top: 0
      behavior: 'smooth'

    return
