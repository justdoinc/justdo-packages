_.extend JustdoTutorials.prototype,
  _immediateInit: ->
    @_registerPlaceholderItems()
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  _registerPlaceholderItems: ->
    JD.registerPlaceholderItem "tutorials-submenu",
      data:
        template: "tutorials_submenu"
        template_data: {}

      domain: "global-right-navbar"
      position: 200

    return