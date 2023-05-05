_.extend JustdoNewProjectTemplates.prototype,
  _immediateInit: ->
    @setupShowFirstJustDoTemplatePickerForNewUserHook()
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  showFirstJustDoTemplatePicker: ->
    options =
      popup_title: "Welcome"
      popup_subtitle: "Start by choosing a template that suit your needs"
      categories: ["getting-started", "blank"]
      allow_closing: false
      target_task: "/"
    APP.justdo_projects_templates.showTemplatesFromCategoriesPicker options
    return

  setupShowFirstJustDoTemplatePickerForNewUserHook: ->
    APP.projects.on "post-reg-init-completed", (init_report) =>
      if init_report.first_project_created isnt false
        Tracker.autorun (computation) =>
          if not (gc = APP.modules.project_page.gridControl(true))?
            return

          if not (grid_ready = gc.ready?.get?())
            return

          @showFirstJustDoTemplatePicker()
          computation.stop()
          return
      return
    return
