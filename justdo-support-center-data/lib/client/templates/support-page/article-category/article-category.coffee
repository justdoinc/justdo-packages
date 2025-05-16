Template.support_page_article_category.onCreated ->
  @parent_tpl = @data.parent_tpl
  @news_category = share.news_category
  @active_tag_rv = @data.active_tag_rv
  return

Template.support_page_article_category.helpers
  tag: ->
    tpl = Template.instance()
    return tpl.active_tag_rv.get()

  articles: ->
    tpl = Template.instance()
    tag = tpl.active_tag_rv.get()
    # Get articles based on the selected tag
    articles = APP.justdo_crm.getAllNewsByCategory(tpl.news_category)
    if tag isnt share.default_tag
      articles = APP.justdo_crm.getItemsByTag(tpl.news_category, tag)

    # Filter articles by search query if provided
    if not _.isEmpty(search_query = tpl.parent_tpl.getSearchQuery())
      search_query = search_query.toLowerCase()
      articles = _.filter articles, (article) ->
        # Search in title and any other relevant article fields
        title = TAPi18n.__(article.title)?.toLowerCase() or ""
        return title.includes(search_query)
        
    return articles
