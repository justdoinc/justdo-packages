Template.user_preference_lang_dropdown.helpers
  supportedLangs: ->
    supported_langs = _.map APP.justdo_i18n.getSupportedLanguages(), (lang_obj, lang_key) -> {_id: lang_key, name: lang_obj.name}

    preferred_lang_tags = APP.justdo_i18n.getBrowserPreferredLanguages()
    preferred_lang_tags = _.without preferred_lang_tags, JustdoI18n.default_lang
      
    preferred_langs = _.filter supported_langs, (lang_obj) -> lang_obj._id in preferred_lang_tags
    supported_langs = _.union(preferred_langs, supported_langs)

    return supported_langs
  
  isLangSelected: ->
    active_lang = APP.justdo_i18n.getLang()
    active_lang_name = APP.justdo_i18n.getSupportedLanguages()[active_lang]?.name
    if @name is active_lang_name
      return "selected"
    return

Template.user_preference_lang_dropdown.events
  "change .user-preference-lang-dropdown": (e, tpl) ->
    lang_tag =  $(e.target).closest("select").val()
    APP.justdo_i18n.setLang lang_tag
    APP.justdo_google_analytics?.sendEvent "user-preference-set-lang-dropdown-#{lang_tag}"
    return