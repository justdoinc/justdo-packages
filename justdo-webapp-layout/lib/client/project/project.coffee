APP.executeAfterAppLibCode ->
  # The reasone we run this code under the 
  # APP.executeAfterAppLibCode
  # is that we want project_page_module.template_helpers to have the template
  # helpers defined in the justdoinc:justdo-task-pane package

  project_page_module = APP.modules.project_page

  main_module = APP.modules.main

  Template.project.created = ->
    main_module.setCustomHeaderTemplate("left", "project_header_global_layout_header_left")
    main_module.setCustomHeaderTemplate("middle", "project_header_global_layout_header_middle")
    main_module.setCustomHeaderTemplate("right", "project_header_global_layout_header_right")

    this.autorun ->
      # Set/update project_page_module.project when it changes
      Router.current() # Just so changing to another project will invalidate the computation

      cur_project = Tracker.nonreactive ->
        project_page_module.project.get()

      if not cur_project?
        APP.logger.debug "Template.project.created: Init project template"
      else
        APP.logger.debug "Template.project.created: Project switched"

      new_proj_id = Iron.controller().project_id

      try
        new_proj = APP.projects.loadProject new_proj_id
      catch e
        APP.logger.error e

        Router.go("dashboard")

        return

      project_page_module.project.set(new_proj)

      Tracker.nonreactive ->
        project_page_module.emit("project-change", project_page_module.curProj())

    # on change in project title:
    this.autorun ->
      if (current_project = JD.activeJustdo({title: 1}))?
        APP.page_title_manager.setPageName current_project.title

    # on change in active task or active task title:
    this.autorun ->
      if (active_task = project_page_module.activeItemId())?
        APP.page_title_manager.setSectionName APP.collections.Tasks.findOne(active_task, {fields: {title: 1}})?.title
      else
        APP.page_title_manager.setSectionName ""

    this.autorun ->
      if not (current_project = project_page_module.curProj())?
        # nothing to do
        return

      project_id = current_project.id

      APP.helpers.subscribeProjectMembersInfo(project_id)

  Template.project.rendered = ->
    project_page_module.initWireframeManager()
    project_page_module.loadKeyboardShortcuts()

    # The following autorun is to ensure that RTL-aware keyboard shortcuts (e.g. indent/outdent) are loaded correctly.
    is_rtl = APP.justdo_i18n.isRtl()
    @autorun ->
      # If language changed but the direction is the same, return.
      if is_rtl is APP.justdo_i18n.isRtl()
        return
      
      is_rtl = APP.justdo_i18n.isRtl()
      project_page_module.unloadKeyboardShortcuts()
      project_page_module.loadKeyboardShortcuts()
      return
    
    return

  Template.project.destroyed = ->
    main_module.unsetCustomHeaderTemplate("middle")
    main_module.unsetCustomHeaderTemplate("right")

    if project_page_module.project?
      project_page_module.helpers.curProj()?.stop()
      project_page_module.project.set(null)

    project_page_module.stopWireframeManager()
    project_page_module.unloadKeyboardShortcuts()

    APP.logger.debug "project template destroyed"

  Template.project.helpers project_page_module.template_helpers

  Template.project.helpers
    belowProjectHeaderItems: ->
      return JD.getPlaceholderItems("below-project-header")
