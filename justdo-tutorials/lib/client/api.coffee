_.extend JustdoTutorials.prototype,
  _immediateInit: ->
    @_registerPlaceholderItems()
    @_registerEventHooks()
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
  
  _registerEventHooks: ->
    APP.projects.on "post-create-new-project", (project_id) ->
      $(".nav-tutorials > .dropdown-toggle").dropdown("toggle")
      return