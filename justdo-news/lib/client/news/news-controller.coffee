JustdoNews.NewsController = ->
  EventEmitter.call this

  return @

Util.inherits JustdoNews.NewsController, EventEmitter

_.extend JustdoNews.NewsController.prototype,
  setTemplateInstance: (tpl) -> @tpl = tpl
  setActiveCategory: (category) -> @tpl?.active_category_rv?.set category
  setActiveNewsId: (news_id) -> @tpl?.active_news_id_rv?.set? news_id
  setActiveTabId: (tab_id) -> @tpl?.active_news_tab_rv?.set tab_id

  
