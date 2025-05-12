Template.support_page_article_category.onCreated ->
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
    if tag is share.default_tag
      return APP.justdo_crm.getAllNewsByCategory(tpl.news_category)
    else
      return APP.justdo_crm.getItemsByTag(tpl.news_category, tag)
