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
      popup_title_i18n: "new_project_template_popup_title"
      popup_subtitle_i18n: "new_project_template_popup_subtitle"
      categories: ["getting-started", "blank"]
      allow_closing: false
      target_task: "/"
    APP.justdo_projects_templates.showTemplatesFromCategoriesPicker options
    return
  
  _showFirstJustDoTemplatePickerForNewUserHandler: (init_report) ->
    if (init_report.first_project_created isnt false) and APP.justdo_new_project_templates.isUserCampaignAllowPickerToShow()
      Tracker.autorun (computation) ->
        if not (gc = APP.modules.project_page.gridControl(true))?
          return

        if not (grid_ready = gc.ready?.get?())
          return

        APP.justdo_new_project_templates.showFirstJustDoTemplatePicker()
        computation.stop()
        return
    return

  setupShowFirstJustDoTemplatePickerForNewUserHook: -> APP.projects.once "post-reg-init-completed", @_showFirstJustDoTemplatePickerForNewUserHandler

  unsetShowFirstJustDoTemplatePickerForNewUserHook: -> APP.projects.off "post-reg-init-completed", @_showFirstJustDoTemplatePickerForNewUserHandler