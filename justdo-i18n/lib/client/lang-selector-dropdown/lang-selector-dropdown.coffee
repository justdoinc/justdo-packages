Template.lang_selector_dropdown.helpers
  activeLanguage: ->
    active_lang = APP.justdo_i18n.getLang()
    return APP.justdo_i18n.getSupportedLanguages()[active_lang]?.name

  supportedLangs: ->
    supported_langs = _.map APP.justdo_i18n.getSupportedLanguages(), (lang_obj, lang_key) -> {_id: lang_key, name: lang_obj.name}

    preferred_lang_tags = APP.justdo_i18n.getBrowserPreferredLanguages()
      
    preferred_langs = _.filter supported_langs, (lang_obj) -> lang_obj._id in preferred_lang_tags
    supported_langs = _.union(preferred_langs, supported_langs)

    chunked_supported_langs = _.chunk(supported_langs, JustdoI18n.lang_dropdown_max_lang_per_col)

    return chunked_supported_langs

  isLangActive: (lang_tag) ->
    return APP.justdo_i18n.getLang() is lang_tag

  shouldSkipLangOption: (lang_tag) ->
    # Don't skip if it's the default language
    if lang_tag is JustdoI18n.default_lang
      return false 
    
    # Get the current path without language prefix
    current_path = APP.justdo_i18n_routes.getCurrentPathWithoutLangPrefix()
    
    # Get the default language path for this current path
    default_lang_path = APP.justdo_i18n_routes.i18nPathAndHrp current_path, JustdoI18n.default_lang
    
    # Get the i18n path for this language
    i18n_path = APP.justdo_i18n_routes.i18nPathAndHrp current_path, lang_tag
    
    # Skip if the path is the same as the default language path (meaning this language is not supported)
    return i18n_path is default_lang_path

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