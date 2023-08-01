_.extend JustdoI18n.prototype,
  _immediateInit: ->
    @setupRouter()
    
    @lang_rv = new ReactiveVar()

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  setLang: (lang) ->
    @lang_rv.set lang
    return
  
  getLang: ->
    return @lang_rv.get() or JustdoI18n.default_lang