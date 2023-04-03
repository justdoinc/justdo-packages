APP.executeAfterAppLibCode ->
  APP.justdo_news.registerNews "news",
    _id: "v3-133"
    title: "v3.133"
    aliases: ["v3-133-x"]
    date: "2022-12-25"
    templates: [
      {
        _id: "main"
        template_name: "version_release_news"
        template_data: [
          {
            title: "Add filter to the quick add bootbox destination selector and owner selector"
            subtitle: "Load more button long emails improvements"
            media_url: "/packages/justdoinc_justdo-news-data/lib/both/news/v3-133/assets/2023_03_10_6.jpg"
          }
        ]
        name: "What's new"
      },
      {
        _id: "features"
        template_name: "version_release_features"
        template_data: [
          {
            title: "Improvements"
            update_items: [
              "1. MailDo: When an email is received, the task owner is now automatically unmuted in the chat."
            ]
          }
        ]
        name: "Other Updates"
      }
    ]
    
  return
