Template.lang_selector_dropdown.helpers
  activeLanguage: ->
    active_lang = APP.justdo_i18n.getLang()
    return APP.justdo_i18n.getSupportedLanguages()[active_lang]?.name

  supportedLangs: ->
    supported_langs = _.map APP.justdo_i18n.getSupportedLanguages(), (lang_obj, lang_key) -> {_id: lang_key, name: lang_obj.name}

    column_langs_count = 16
    chunked_langs = _.chunk(supported_langs, column_langs_count)

    return chunked_langs

Template.lang_selector_dropdown.events
  "click .dropdown-item": (e, tpl) ->
    lang_tag =  $(e.target).closest(".dropdown-item").data("lang-tag")
    APP.justdo_i18n.setLang lang_tag, {skip_set_user_lang: true}
    APP.justdo_google_analytics?.sendEvent "set-lang-dropdown-#{lang_tag}"
    return
