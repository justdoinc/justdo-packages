APP.justdo_crm.registerNews "news",
  _id: "v5-4"
  aliases: ["v5-4-x"]
  date: "2024-12-25"
  title: "JustDo v5.4"

  templates: [
    {
      _id: "main"
      template_name: "version_release_news"
      template_data: {
        news_array: [
          {
            "title": "Introduce System Info to the JustDo's site admin section"
            "subtitle": "A new panel within the JustDo admin dashboard that highlights key server stats."
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5-4/assets/2.png"
          },
          {
            "title": "Allow the Bottom Pane to expand to the full height of the window"
            "subtitle": "With this update, the bottom panel expands to the full browser window height with a single click."
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5-4/assets/1.png"
          }
        ]
      }
      name: "What's new"
      page_title: "Title"
      page_description: "Description"
      h1: "h1"
    },
    {
      _id: "features"
      template_name: "version_release_features"
      template_data: {
        title: "Improvements"
        update_items: [
          "1. New icons for Projects - and other icons updates.",
          "2. Distinguish between Project and Closed Project in the Type field.",
          "3. Format better Numbers and Smart Numbers fields, separate thousands locale aware."
        ]
      }
      name: "Other Updates"
      page_title: "Title"
      page_description: "Description"
      h1: "h1"

    }
  ]
