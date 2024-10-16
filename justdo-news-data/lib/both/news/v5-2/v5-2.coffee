APP.justdo_crm.registerNews "news",
  _id: "v5-2"
  aliases: ["v5-2-x"]
  date: "2024-10-15"

  # title is used in the dropdown as the name of the item (e.g. v5.2)
  title: "v5_2_news_title"

  templates: [
    {
      _id: "main"
      # name is the tab name (e.g. What's new)
      name: "v5_2_news_main_name"
      # The following two properties are used in the SEO meta tags
      page_title: "v5_2_news_page_title"
      page_description: "v5_2_news_page_description"

      h1: "v5_2_news_page_title"
      subtitle: "v5_2_news_main_array_item_0_subtitle"

      template_name: "version_release_news"
      template_data: {
        news_array: [
          {
            "title": "v5_2_news_main_array_item_1_title"
            "subtitle": "v5_2_news_main_array_item_1_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5-2/assets/1.png"
          },
          {
            "title": "v5_2_news_main_array_item_2_title"
            "subtitle": "v5_2_news_main_array_item_2_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5-2/assets/2.png"
          },
          {
            "title": "v5_2_news_main_array_item_3_title"
            "subtitle": "v5_2_news_main_array_item_3_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5-2/assets/3.png"
          },
          {
            "title": "v5_2_news_main_array_item_4_title"
            "subtitle": "v5_2_news_main_array_item_4_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v5-2/assets/4.png"
          }
        ]
      }
    }
  ]
