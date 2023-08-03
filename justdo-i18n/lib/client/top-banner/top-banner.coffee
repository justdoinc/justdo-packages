Template.top_banner.onCreated ->
  @hide_top_banner_rv = new ReactiveVar false
  return

Template.top_banner.helpers
  showTopBanner: -> 
    tpl = Template.instance()

    is_landing_page_type_marketing = env.LANDING_PAGE_TYPE is "marketing"
    is_campaign_shows_top_banner = APP.justdo_promoters_campaigns.getCampaignDoc().show_lang_selector_header
    is_default_lang_selected = APP.justdo_i18n.getLang() is JustdoI18n.default_lang
    is_top_banner_hidden_by_local_storage = amplify.store JustdoI18n.amplify_hide_top_banner_key
    is_user_logged_in = Meteor.userId()?

    return is_landing_page_type_marketing and is_campaign_shows_top_banner and not is_default_lang_selected and not is_top_banner_hidden_by_local_storage and not tpl.hide_top_banner_rv.get() and not is_user_logged_in

  defaultLang: ->
    lang_name = APP.justdo_i18n.getSupportedLanguages()[JustdoI18n.default_lang].name
    return {_id: JustdoI18n.default_lang, name: lang_name}

Template.top_banner.events
  "click .language-suggestion": (e, tpl) ->
    lang_tag = $(e.target).closest(".set-default-lang").data "lang-tag"
    APP.justdo_i18n.setLang lang_tag, {save_to_local_storage: true}
    APP.justdo_google_analytics?.sendEvent "set-lang-top-banner-#{lang_tag}"
    return
  
  "click .top-banner-close": (e, tpl) ->
    tpl.hide_top_banner_rv.set true
    amplify.store JustdoI18n.amplify_hide_top_banner_key, true
    APP.justdo_google_analytics?.sendEvent "top-banner-close"
    return