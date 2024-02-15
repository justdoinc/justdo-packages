APP.justdo_news.registerNews "news",
  _id: "v5-0"
  title: "v5.0"
  aliases: ["v5-0-x"]
  date: "2024-02-15"
  templates: [
    {
      _id: "main"
      template_name: "version_release_news"
      template_data: {
        news_array: [
          {
            "title": "New search dropdown"
            "subtitle": "The new search dropdown instantly displays results, speeding up and simplifying searches."
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5/assets/1.jpg"
          },
          {
            "title": "Introduce the Solid Orange theme"
            "subtitle": ""
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5/assets/2.jpg"
          }
        ]
      }
      name: "What's new"
    }
    ,
    {
      _id: "features"
      template_name: "version_release_features"
      template_data: {
        title: "Improvements"
        update_items: [
          "1. Smart numbers: improve numbers rounding and formatting."
        ]
      }
      name: "Other Updates"
    }
  ]
