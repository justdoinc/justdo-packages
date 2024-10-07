_.extend JustdoI18nRoutes,
  plugin_human_readable_name: "justdo-i18n-routes"

  langs_url_prefix: "/lang" # IMPORTANT! Trailing slash is not allowed!

  human_readable_url_separator: "--"

  # This is meant to be used in new RegExp() constructor
  human_readable_chars_regex_string: "(?:\\w|%|-)"