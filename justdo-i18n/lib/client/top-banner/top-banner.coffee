Template.top_banner.helpers
  showTopBanner: -> (env.LANDING_PAGE_TYPE is "marketing") and (APP.justdo_i18n.getLang() isnt JustdoI18n.default_lang)

  defaultLang: ->
    lang_name = APP.justdo_i18n.getSupportedLanguages()[JustdoI18n.default_lang].name
    return {_id: JustdoI18n.default_lang, name: lang_name}

Template.top_banner.events
  "click .language-suggestion": (e, tpl) ->
    lang_tag = $(e.target).closest(".set-default-lang").data "lang-tag"
    APP.justdo_i18n.setLang lang_tag, {save_to_local_storage: true}
    APP.justdo_google_analytics?.sendEvent "set-lang-banner-#{lang_tag}"
    return