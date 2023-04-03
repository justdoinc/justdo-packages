VERSION = "v3-136"
DATE = "2023-03-31"

news = [
  {
    "title": "New landing page"
    "subtitle": "Introducing Our Refreshed Landing Page 🎉"
    "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v3-136/assets/2023_03_10_1.jpg"
  },
  {
    "title": "Custom states"
    "subtitle": "Boost your workflow efficiency with our latest addition - Custom States. Tailor task states to suit your unique project needs and track progress with greater precision."
    "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v3-136/assets/2023_03_10_3.jpg"
  },
  {
    "title": "Stay Informed with On-Grid Unread Emails Indicator"
    "subtitle": "Never miss important updates again! Our new On-Grid Unread Emails Indicator keeps you informed about unread emails within tasks, ensuring efficient communication and prompt action."
    "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v3-136/assets/2023_03_10_5.jpg"
  },
  {
    "title": "Enhanced Filters for Quick Add Dialog"
    "subtitle": "Boost your productivity with our newly added filters for the Quick Add Bootbox Destination and Owner Selector. Streamline task creation by finding the right destination and owner with ease."
    "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v3-136/assets/2023_03_10_6.jpg"
  }
]

updates = [
  {
    "title": "Improvements"
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

  if Meteor.isServer
    return

  Template.v3_136_news.helpers
    news: -> news
    date: -> moment(DATE, "YYYY-MM-DD").format "DD MMMM YYYY"
  Template.v3_136_features.helpers
    updates: ->
      updates =  _.map updates, (update) ->
        update.date = moment(DATE, "YYYY-MM-DD").format "DD MMMM YYYY"
        return update
      return updates
