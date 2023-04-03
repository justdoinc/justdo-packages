VERSION = "v3-133"
DATE = "2022-12-25"

news = [
  {
    "title": "Add filter to the quick add bootbox destination selector and owner selector"
    "subtitle": "Load more button long emails improvements"
    "media_url": "/packages/justdoinc_justdo-news/lib/client/news/v3-133/assets/2023_03_10_6.jpg"
  }
]

updates = [
  {
    "title": "Improvements"
    "date": "25 Dec 2022"
    "update_items": [
      "1. MailDo: When an email is received, the task owner is now automatically unmuted in the chat."
    ]
  }
]

APP.executeAfterAppLibCode ->
  APP.justdo_news.registerNews "news",
    _id: VERSION
    title: VERSION.replace "-", "."
    aliases: ["#{VERSION}-x"]
    date: DATE
    templates:[
      _id: "main"
      template_name: "#{VERSION.replace "-", "_"}_news"
      name: "What's new"
    ,
      _id: "features"
      template_name: "#{VERSION.replace "-", "_"}_features"
      name: "Other Updates"
    ]

  Template.v3_133_news.helpers
    news: -> news
    date: -> moment(DATE, "YYYY-MM-DD").format "DD MMMM YYYY"
  Template.v3_133_features.helpers
    updates: -> updates
