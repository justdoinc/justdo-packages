Template.lang_selector_dropdown.helpers
  activeLanguage: ->
    active_lang = APP.justdo_i18n.getLang()
    return APP.justdo_i18n.getSupportedLanguages()[active_lang]?.name

  supportedLangs: ->
    supported_langs = _.map APP.justdo_i18n.getSupportedLanguages(), (lang_obj, lang_key) -> {_id: lang_key, name: lang_obj.name}
    supported_langs = JustdoHelpers.localeAwareSortCaseInsensitive supported_langs, (lang_obj) -> lang_obj.name

    preferred_lang_tags = APP.justdo_i18n.getBrowserPreferredLanguages()
    # If the user's preferred language is not the default language, we add it to the preferred languages list
    if APP.justdo_i18n.getLang() isnt JustdoI18n.default_lang
      preferred_lang_tags.push JustdoI18n.default_lang
    else
      preferred_lang_tags = _.without preferred_lang_tags, JustdoI18n.default_lang
      
    preferred_langs = _.filter supported_langs, (lang_obj) -> lang_obj._id in preferred_lang_tags

    chunked_preferred_langs = _.chunk(preferred_langs, JustdoI18n.lang_dropdown_max_lang_per_col)
    chunked_supported_langs = _.chunk(supported_langs, JustdoI18n.lang_dropdown_max_lang_per_col)

    return {preferred_langs: chunked_preferred_langs, supported_langs: chunked_supported_langs}

  isLangActive: (lang_tag) ->
    return APP.justdo_i18n.getLang() is lang_tag

Template.lang_selector_dropdown.events
  "click .dropdown-item": (e, tpl) ->
    lang_tag =  $(e.target).closest(".dropdown-item").data("lang-tag")
    APP.justdo_i18n.setLang lang_tag, {skip_set_user_lang: true}
    APP.justdo_google_analytics?.sendEvent "set-lang-dropdown-#{lang_tag}"
    return

  "click .footer-languag-improve-btn": ->
    APP.justdo_google_analytics?.sendEvent "footer-languag-improve-btn", {lang: APP.justdo_i18n.getLang()}

    route_name = APP.justdo_i18n_routes?.getCurrentRouteName() or Router.current()?.route.getName()

    APP.justdo_i18n.getProofreaderDoc APP.justdo_i18n.getRouteProofreadingScope route_name

    return