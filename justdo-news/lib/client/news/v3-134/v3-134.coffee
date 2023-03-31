VERSION = "v3-134"
DATE = "2023-02-10"

news = [
  {
    "title": "New landing page"
    "subtitle": "Energistically productivate orthogonal partnerships via economically sound leadership skills"
    "media_url": "/packages/justdoinc_justdo-news/lib/client/news/v3-134/assets/2023_03_10_1.jpg"
  },
  {
    "title": "Custom states"
    "subtitle": "Dynamically recaptiualize process-centric infrastructures before future-proof opportunities. Proactively pontificate economically sound innovation"
    "media_url": "/packages/justdoinc_justdo-news/lib/client/news/v3-134/assets/2023_03_10_3.jpg"
  },
  {
    "title": "On-grid unread emails indicator"
    "subtitle": "Load more button long emails improvements"
    "media_url": "/packages/justdoinc_justdo-news/lib/client/news/v3-134/assets/2023_03_10_5.jpg"
  },
  {
    "title": "Add filter to the quick add bootbox destination selector and owner selector"
    "subtitle": "Load more button long emails improvements"
    "media_url": "/packages/justdoinc_justdo-news/lib/client/news/v3-134/assets/2023_03_10_6.jpg"
  }
]

updates = [
  {
    "title": "Improvements"
    "date": "10 March 2023"
    "update_items": [
      "1. Performance improvement for operations that involves updates to more than 1k tasks, in particular, changing tasks members of a sub-tree bigger than 1k users.",
      "2. Activity tab: Fix activity log not showing correctly if it is a parent-add and the parent is removed <a href='https://drive.google.com/file/d/1StWLN86xWT2hlafgyG8pdwB2aBPJipD6/view?usp=share_link' target='blank'>video</a>.",
      "3. Upload avatars for environments that use JustDo files.",
      "4. Introduced the Organizations concept: an optional logic unit above JustDos.",
      "5. MailDo: When an email is received, the task owner is now automatically unmuted in the chat."
    ]
  }
]

APP.executeAfterAppLibCode ->
  APP.justdo_news.registerNews
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

  Template.v3_134_news.helpers
    news: -> news
    date: -> moment(DATE, "YYYY-MM-DD").format "DD MMMM YYYY"
  Template.v3_134_features.helpers
    updates: -> updates
