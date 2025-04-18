Template.top_banner.onCreated ->
  @hide_top_banner_rv = new ReactiveVar false
  return

Template.top_banner.helpers
  showTopBanner: -> 
    tpl = Template.instance()

    is_campaign_shows_top_banner = APP.justdo_promoters_campaigns?.getCampaignDoc().show_lang_selector_header
    is_default_lang_selected = APP.justdo_i18n.getLang() is JustdoI18n.default_lang
    is_top_banner_hidden_by_local_storage = amplify.store JustdoI18n.amplify_hide_top_banner_key
    is_user_logged_in = Meteor.userId()?

    return is_campaign_shows_top_banner and not is_default_lang_selected and not is_top_banner_hidden_by_local_storage and not tpl.hide_top_banner_rv.get() and not is_user_logged_in

  defaultLang: ->
    lang_name = APP.justdo_i18n.getSupportedLanguages()[JustdoI18n.default_lang].name
    return {_id: JustdoI18n.default_lang, name: lang_name}

Template.top_banner.events
  "click .language-suggestion": (e, tpl) ->
    APP.justdo_i18n.setLang JustdoI18n.default_lang, {skip_set_user_lang: true}
    APP.justdo_google_analytics?.sendEvent "set-lang-top-banner-#{JustdoI18n.default_lang}"
    return
  
  "click .top-banner-close": (e, tpl) ->
    tpl.hide_top_banner_rv.set true
    amplify.store JustdoI18n.amplify_hide_top_banner_key, true
    APP.justdo_google_analytics?.sendEvent "top-banner-close"
    return