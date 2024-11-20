_.extend JustdoI18n,
  plugin_human_readable_name: "justdo-i18n"
  default_lang: "en"
  amplify_lang_key: "lang"
  amplify_hide_top_banner_key: "hide_top_banner"
  supported_rtl_langs: ["he", "ar", "yi"] # RTL will be enabled for these languages
  # Translates our format of lang tag to Vimeo's
  vimeo_lang_tags:
    "zh-TW": "zh-Hant"
  lang_dropdown_max_lang_per_col: 16
  default_non_i18n_route_proofreading_scope: {all_keys: true} # The scope we use when the route isn't i18n (available only in english);
                                                              # {all_keys: true} means that we download all keys in the environment
  default_i18n_route_proofreading_scope: {} # The scope we use when the route is i18nable;
                                            # {} means that we download keys that we've encountered
  supported_language_group_types: [
    "all"
    "core"
    "default"
  ]