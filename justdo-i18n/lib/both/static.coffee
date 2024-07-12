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
  proofreading_scope:
    landing_page_layout_templates: ["top_banner", "header", "main_menu", "footer"]
    default_tab_title_and_descriptions: [/^default_tab_.*$/]