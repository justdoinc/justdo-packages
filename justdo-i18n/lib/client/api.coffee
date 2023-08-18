_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @lang_rv = new ReactiveVar amplify.store JustdoI18n.amplify_lang_key

    @tap_i18n_set_lang_tracker = Tracker.autorun =>
      lang = @getLang()
      TAPi18n.setLanguage lang
      i18n?.setLanguage lang
      return

    @_setupBeforeUserSignUpHook()

    @onDestroy =>
      @tap_i18n_set_lang_tracker?.stop?()
      return

    return

  _deferredInit: ->
    if @destroyed
      return

    return
  
  _setupBeforeUserSignUpHook: ->
    APP.accounts.on "user-signup", (options) =>
      if (lang = @getLang())?
        options.profile.lang = lang
      return
      
    return

  setLang: (lang, options) ->
    # options:
    #   save_to_local_storage: Boolean (optional) - Saves lang to local storage. Has no affect if current user is logged in.
    if Meteor.user()?
      @setUserLang lang
    else
      @lang_rv.set lang
      if options?.save_to_local_storage
        amplify.store JustdoI18n.amplify_lang_key, lang
    return
  
  getLang: ->
    if Meteor.user()?
      return @getUserLang() or JustdoI18n.default_lang

    if (lang = @lang_rv.get())?
      return lang

    if (campaign_lang = APP.justdo_promoters_campaigns?.getCampaignDoc()?.lang)?
      return campaign_lang
        
    return JustdoI18n.default_lang
    
  generateI18nModalButtonLabel: (label) ->
    return JustdoHelpers.renderTemplateInNewNode("modal_button_label", {label})