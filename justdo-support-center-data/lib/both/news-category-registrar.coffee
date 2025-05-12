  template: "support_page_article"
APP.justdo_crm.registerCategory share.news_category, 
  # XXX Remove after i18n for support articles is ready
  translatable: false
  title_in_url: true

# XXX Remove after i18n for support articles is ready
APP.justdo_i18n.forceLtrForRoute "#{share.news_category}_page_with_news_id"
