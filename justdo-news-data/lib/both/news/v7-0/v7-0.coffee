zimExcludedListingCondition = -> not JustdoHelpers.isBespokePackageEnabled env, Zim?.bespoke_pack_id 

APP.justdo_crm.registerNews "news",
  _id: "v7-0"
  aliases: ["v7-0-x"]
  date: "2025-09-30"
  title: "v7_0_news_title"

  templates: [
    {
      _id: "main"
      template_name: "version_release_news"
      name: "v7_0_news_main_name"
      page_hrp: "v7_0_news_page_hrp"
      page_title: "v7_0_news_page_title"
      page_description: "v7_0_news_page_description"

      h1: "v7_0_news_page_main_h1"
      subtitle: "v7_0_news_main_array_item_0_subtitle"

      template_data: {
        news_array: [
          {
            "title": "v7_0_news_main_array_item_1_title",
            "subtitle": "v7_0_news_main_array_item_1_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v7-0/assets/2.png"
            "listingCondition": zimExcludedListingCondition
            
          },

          {
            "subtitle": "v7_0_news_main_array_item_2_subtitle",
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v7-0/assets/1.png"
            "listingCondition": zimExcludedListingCondition
          },

          {
            "title": "v7_0_news_main_array_item_3_title",
            "subtitle": "v7_0_news_main_array_item_3_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v7-0/assets/3.png"
          },

          {
            "title": "v7_0_news_main_array_item_6_title",
            "subtitle": "v7_0_news_main_array_item_6_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v7-0/assets/6.png"
          },

          {
            "title": "v7_0_news_main_array_item_4_title",
            "subtitle": "v7_0_news_main_array_item_4_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v7-0/assets/4.png"
          },

          {
            "title": "v7_0_news_main_array_item_5_title",
            "subtitle": "v7_0_news_main_array_item_5_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v7-0/assets/5.png"
          },

          {
            "title": "v7_0_news_main_array_item_7_title",
            "subtitle": "v7_0_news_main_array_item_7_subtitle"
            "media_url": "/packages/justdoinc_justdo-news-data/lib/both/news/v7-0/assets/8.png"
          },

          {
            "title": "v7_0_news_main_array_item_8_title",
            "subtitle": "v7_0_news_main_array_item_8_subtitle"
          }
        ]
      }
    }
  ]
