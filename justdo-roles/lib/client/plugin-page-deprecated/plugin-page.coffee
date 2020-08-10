# Read the comment in the header of lib/both/router-deprecated.coffee

APP.executeAfterAppLibCode ->
  main_module = APP.modules.main

  _.extend JustdoRoles.prototype,
    current_project: null
    current_project_dep: new Tracker.Dependency()

    unloadProject: ->
      if @current_project?
        @current_project.stop()

        APP.modules.project_page.project.set(null) # A hack to make the project header title editor work

        @current_project = null

      return

    loadProject: (project_id) ->
      # Will raise exception if projct_id can't be loaded.

      @unloadProject()

      @current_project = APP.projects.loadProject project_id

      APP.modules.project_page.project.set(@current_project) # A hack to make the project header title editor work

      @current_project_dep.changed()

      return

    getProject: ->
      @current_project_dep.depend()

      return @current_project

  justdoRoles = -> APP.justdo_roles

  Template.justdo_roles_page.onCreated ->
    main_module.setCustomHeaderTemplate("middle", "project_header_global_layout_header_middle")

    @autorun ->
      # Set/update module.project when it changes
      Router.current() # Just so changing to another project will invalidate the computation

      project_id = Iron.controller().project_id

      try
        justdoRoles().loadProject project_id
      catch e
        APP.logger.error e

        Router.go("dashboard")

        return

      Tracker.onInvalidate ->
        justdoRoles().unloadProject()

        return

    @autorun ->
      # on change in project title
      if (project = justdoRoles().getProject())?
        APP.page_title_manager.setPageName "#{project.getProjectDoc({fields: {title: 1}})?.title} Roles & Groups"

      return

    @autorun ->
      # Load the info about the projects members (including removed ones)
      if not (project = justdoRoles().getProject())?
        # nothing to do
        return

      project_id = project.id

      APP.helpers.subscribeProjectMembersInfo(project_id)

      return

    return

  Template.justdo_roles_page.helpers {}

  Template.justdo_roles_page.events {}

  Template.justdo_roles_page.destroyed = ->
    main_module.unsetCustomHeaderTemplate("middle")

    return