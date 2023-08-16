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
    showTutorialDropdownAndPrevrentClose = =>
      $(".nav-tutorials > .dropdown-toggle").dropdown("toggle")
      @force_tutorial_dropdown_open_hook?.off?()
      @force_tutorial_dropdown_open_hook = $(".nav-tutorials").on "hide.bs.dropdown", -> false
      return

    APP.projects.on "post-create-new-project", (project_id) =>
      showTutorialDropdownAndPrevrentClose()
      return
    
    APP.projects.once "post-reg-init-completed", (init_report) =>        
      if init_report.first_project_created isnt false
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
