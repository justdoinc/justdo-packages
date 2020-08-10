APP.executeAfterAppLibCode ->
  # The reasone we run this code under the 
  # APP.executeAfterAppLibCode
  # is that we want module.template_helpers to have the template
  # helpers defined in the justdoinc:justdo-task-pane package

  module = APP.modules.project_page

  main_module = APP.modules.main

  Template.project.created = ->
    main_module.setCustomHeaderTemplate("middle", "project_header_global_layout_header_middle")
    main_module.setCustomHeaderTemplate("right", "project_header_global_layout_header_right")

    this.autorun ->
      # Set/update module.project when it changes
      Router.current() # Just so changing to another project will invalidate the computation

      cur_project = Tracker.nonreactive ->
        module.project.get()

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

      module.project.set(new_proj)

      Tracker.nonreactive ->
        module.emit("project-change", module.curProj())

    # on change in project title:
    this.autorun ->
      if (current_project = JD.activeJustdo({title: 1}))?
        APP.page_title_manager.setPageName current_project.title

    # on change in active task or active task title:
    this.autorun ->
      if (active_task = module.activeItemId())?
        APP.page_title_manager.setSectionName APP.collections.Tasks.findOne(active_task)?.title
      else
        APP.page_title_manager.setSectionName ""

    this.autorun ->
      if not (current_project = module.curProj())?
        # nothing to do
        return

      project_id = current_project.id

      APP.helpers.subscribeProjectMembersInfo(project_id)

  Template.project.rendered = ->
    module.initWireframeManager()
    module.loadKeyboardShortcuts()

  Template.project.destroyed = ->
    main_module.unsetCustomHeaderTemplate("middle")
    main_module.unsetCustomHeaderTemplate("right")

    if module.project?
      module.helpers.curProj()?.stop()
      module.project.set(null)

    module.stopWireframeManager()
    module.unloadKeyboardShortcuts()

    APP.logger.debug "project template destroyed"

  Template.project.helpers module.template_helpers
