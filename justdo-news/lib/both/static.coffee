_.extend JustdoNews,
  plugin_human_readable_name: "justdo-news"

  root_path_regex: /^\/([A-Z]|[a-z]|\d|-)+/g

  default_news_category_template: "news"

  default_news_template: "main"

  default_news_template_key_to_determine_supported_langs: "page_title"