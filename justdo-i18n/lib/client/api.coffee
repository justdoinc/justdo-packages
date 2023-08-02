_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @lang_rv = new ReactiveVar()

    @tap_i18n_set_lang_tracker = Tracker.autorun =>
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

  setLang: (lang) ->
    if Meteor.user()?
      @setUserLang lang
    else
      @lang_rv.set lang
    return
  
  getLang: ->
    if Meteor.user()?
      return @getUserLang() or JustdoI18n.default_lang

    if (lang = @lang_rv.get())?
      return lang

    if (campaign_lang = APP.justdo_promoters_campaigns?.getCampaignDoc()?.lang)?
      return campaign_lang
        
    return JustdoI18n.default_lang
    