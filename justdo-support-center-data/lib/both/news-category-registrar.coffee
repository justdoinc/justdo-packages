APP.justdo_crm.registerCategory share.news_category, 
  template: "support_page"
  translatable: true
  title_in_url: true
  auto_redirect_to_most_recent_news: false

# XXX Remove after i18n for support articles is ready
APP.justdo_i18n.forceLtrForRoute "#{share.news_category}_page"
APP.justdo_i18n.forceLtrForRoute "#{share.news_category}_page_with_news_id"
