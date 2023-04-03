APP.justdo_news.registerNews "news",
  _id: "v3-136"
  title: "v3.136"
  aliases: ["v3-136-x"]
  date: "2023-03-31"
  templates: [
    {
      _id: "main"
      template_name: "version_release_news"
      template_data: {
        news_array: [
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
      }
      name: "What's new"
    },
    {
      _id: "features"
      template_name: "version_release_features"
      template_data: {
        title: "Improvements"
        update_items: [
          "1. Performance improvement for operations that involves updates to more than 1k tasks, in particular, changing tasks members of a sub-tree bigger than 1k users.",
          "2. Activity tab: Fix activity log not showing correctly if it is a parent-add and the parent is removed <a href='https://drive.google.com/file/d/1StWLN86xWT2hlafgyG8pdwB2aBPJipD6/view?usp=share_link' target='blank'>video</a>.",
          "3. Upload avatars for environments that use JustDo files.",
          "4. Introduced the Organizations concept: an optional logic unit above JustDos.",
          "5. MailDo: When an email is received, the task owner is now automatically unmuted in the chat."
        ]
      }
      name: "Other Updates"
    }
  ]

return
