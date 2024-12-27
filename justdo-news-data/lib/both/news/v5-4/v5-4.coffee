APP.justdo_crm.registerNews "news",
  _id: "v5-4"
  aliases: ["v5-4-x"]
  date: "2024-12-25"
  title: "v5_4_news_title"

  templates: [
    {
      _id: "main"
      template_name: "version_release_news"
      name: "v5_4_news_main_name"
      page_title: "v5_4_news_page_title"
      page_description: "v5_4_news_page_description"

      h1: "v5_4_news_page_title"
      subtitle: "v5_4_news_main_array_item_0_subtitle"

      template_data: {
        news_array: [
          {
            "title": "v5_4_news_main_array_item_1_title"
            "subtitle": "v5_4_news_main_array_item_1_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5-4/assets/1.png"
          },
          {
            "title": "v5_4_news_main_array_item_2_title"
            "subtitle": "v5_4_news_main_array_item_2_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5-4/assets/2.png"
          }
          {
            "title": "v5_4_news_main_array_item_3_title"
            "subtitle": "v5_4_news_main_array_item_3_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5-4/assets/2.png"
          }
        ]
      }
    },
    {
      _id: "features"
      template_name: "version_release_features"
      template_data: {
        title: "v5_4_news_features_title"
        update_items: "v5_4_news_features_update_items"
      }
      name: "v5_4_news_features_name"
      page_title: "v5_4_news_page_title"
      page_description: "v5_4_news_page_description"
      h1: "v5_4_news_page_title"
    }
  ]
