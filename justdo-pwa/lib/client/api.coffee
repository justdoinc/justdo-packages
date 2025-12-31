_.extend JustdoPwa.prototype,
  _immediateInit: ->
    @_setupGlobalTemplateHelpers()
    return

  _deferredInit: ->
    if @destroyed
      return

    return
  
  _setupGlobalTemplateHelpers: ->
    Template.registerHelper "hideInMobileLayout", (display_mode) ->
      if not display_mode?
        display_mode = "block"
      
      return "d-none d-md-#{display_mode}"
      
    return
