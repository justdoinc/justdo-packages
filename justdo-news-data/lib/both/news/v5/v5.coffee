APP.justdo_news.registerNews "news",
  _id: "v5-0"
  title: "v5_news_title"
  aliases: ["v5-0-x"]
  date: "2024-02-15"
  templates: [
    {
      _id: "main"
      template_name: "version_release_news"
      template_data: {
        news_array: [
          {
            "title": "v5_news_main_array_item_1_title"
            "subtitle": "v5_news_main_array_item_1_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5/assets/1.jpg"
          },
          {
            "title": "v5_news_main_array_item_2_title"
            "subtitle": ""
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5/assets/2.jpg"
          }
        ]
      }
      name: "v5_news_main_name"
    }
    ,
    {
      _id: "features"
      template_name: "version_release_features"
      template_data: {
        title: "v5_news_features_title"
        update_items: "v5_news_features_update_items"
      }
      name: "v5_news_features_name"
    }
  ]
