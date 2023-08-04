_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @lang_rv = new ReactiveVar amplify.store JustdoI18n.amplify_lang_key

    @tap_i18n_set_lang_tracker = Tracker.autorun =>
      # To trigger reacticity from justdo_promoters_campaigns's setupUrlCampaignDetector
      # As getLang from campaign doc will return the default one upon first load
      # Since it consumes the campaign id in url, rewrites the url and only then stores the campaign id in local storage
      Router.current() 
      TAPi18n.setLanguage @getLang()
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
    