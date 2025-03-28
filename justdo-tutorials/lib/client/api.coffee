_.extend JustdoTutorials.prototype,
  _immediateInit: ->
    @is_tutorial_dropdown_allowed_to_close = true
    @_registerPlaceholderItems()
    return

  _deferredInit: ->
    if @destroyed
      return

    Tracker.autorun (computation) =>
      if not Meteor.user()?
        return

      @_registerEventHooks()
      computation.stop()
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
    showTutorialDropdownAndPrevrentClose = =>
      $(".nav-tutorials > .dropdown-toggle").dropdown("toggle")
      $(".nav-tutorials.dropdown").addClass "highlighted"
      
      @is_tutorial_dropdown_allowed_to_close = false

      return
    
    # This take care of the first justdo created for user upon registration
    APP.projects.once "post-reg-init-completed", (init_report) =>        
      Tracker.autorun (computation) =>
        if not (gc = APP.modules.project_page.gridControl(true))?
          return

        if not (grid_ready = gc.ready?.get?())
          return

        showTutorialDropdownAndPrevrentClose()
        computation.stop()
        return

      return

    return