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
    if APP.justdo_promoters_campaigns?.getCampaignDoc().open_tutorial_dropdown_upon_project_creation is true
      showTutorialDropdownAndPrevrentClose = =>
        $(".nav-tutorials > .dropdown-toggle").dropdown("toggle")
        $(".nav-tutorials.dropdown").addClass "highlighted"
        
        @is_tutorial_dropdown_allowed_to_close = false

        return

      # This take care regular create justdo calls
      APP.projects.on "post-create-new-project", (project_id) =>
        showTutorialDropdownAndPrevrentClose()
        return
      
      # This take care of the first justdo created for user upon registration
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