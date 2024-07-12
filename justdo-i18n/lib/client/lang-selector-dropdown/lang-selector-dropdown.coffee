Template.lang_selector_dropdown.helpers
  activeLanguage: ->
    active_lang = APP.justdo_i18n.getLang()
    return APP.justdo_i18n.getSupportedLanguages()[active_lang]?.name

  supportedLangs: ->
    supported_langs = _.map APP.justdo_i18n.getSupportedLanguages(), (lang_obj, lang_key) -> {_id: lang_key, name: lang_obj.name}

    chunked_langs = _.chunk(supported_langs, JustdoI18n.lang_dropdown_max_lang_per_col)

    return chunked_langs

  isDefaultLang: ->
    return APP.justdo_i18n.getLang() is JustdoI18n.default_lang

Template.lang_selector_dropdown.events
  "click .dropdown-item": (e, tpl) ->
    lang_tag =  $(e.target).closest(".dropdown-item").data("lang-tag")
    APP.justdo_i18n.setLang lang_tag, {skip_set_user_lang: true}
    APP.justdo_google_analytics?.sendEvent "set-lang-dropdown-#{lang_tag}"
    return

  "click .footer-languag-improve-btn": ->
    APP.justdo_google_analytics?.sendEvent "footer-languag-improve-btn", {lang: APP.justdo_i18n.getLang()}

    route_name = APP.justdo_i18n_routes?.getCurrentRouteName() or Router.current()?.route.getName()
    proofreading_scope = APP.justdo_i18n.getRouteProofreadingScope route_name
    # Note that we're explicitly NOT using API from justdo_i18n_routes to determine if the current route is i18nable
    # because justdo_i18n_routes may not be available in all environments.
    is_cur_route_i18nable = Router.routes[route_name]?.options?.translatable

    if not proofreading_scope?
      if is_cur_route_i18nable
        proofreading_scope = 
          exclude_templates: JustdoI18n.proofreading_scope.landing_page_layout_templates
          exclude_keys: JustdoI18n.proofreading_scope.common_excluded_keys
      else
        proofreading_scope = {all_keys: true}
  
    APP.justdo_i18n.getProofreaderDoc proofreading_scope

    return