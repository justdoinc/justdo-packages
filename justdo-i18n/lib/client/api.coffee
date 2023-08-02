_.extend JustdoI18n.prototype,
  _immediateInit: ->
    # lang_rv is not used at the moment, but reserved for future uses like language menu.
    @lang_rv = new ReactiveVar()

    @tap_i18n_set_lang_tracker = Tracker.autorun =>
      TAPi18n.setLanguage @getLang()
      return

    @onDestroy =>
      @tap_i18n_set_lang_tracker?.stop?()
      return

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  setLang: (lang) ->
    @lang_rv.set lang
    return
  
  getLang: ->
    return @getUserLang() or JustdoI18n.default_lang
