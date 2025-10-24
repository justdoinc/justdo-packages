APP.justdo_crm.registerItem share.news_category,
  _id: "monday-com-migration"
  title: "migrate_monday_to_justdo_page_title"
  aliases: ["monday", "monday-migration", "monday-to-justdo"]
  tags: ["advanced", "web-version"]
  date: "2025-10-24"
  templates: [
    {
      _id: "main"
      template_name: "support_article_migrate_from_monday_to_justdo"
      name: "migrate_monday_to_justdo_page_title"
      h1: "migrate_monday_to_justdo_page_title"
      page_title: "migrate_monday_to_justdo_page_title"
      page_description: "migrate_monday_to_justdo_page_description"
    }
  ]

if Meteor.isClient
  Template.support_article_migrate_from_monday_to_justdo.onCreated ->
    APP.justdo_i18n.removeForceLtrForRoute "#{share.news_category}_page_with_news_id"
    return

  Template.support_article_migrate_from_monday_to_justdo.onDestroyed ->
    APP.justdo_i18n.forceLtrForRoute "#{share.news_category}_page_with_news_id"
    return