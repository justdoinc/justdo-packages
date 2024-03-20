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
    self = @

    if APP.justdo_promoters_campaigns?
      is_new_project_template_picker_allowed_to_show = APP.justdo_promoters_campaigns.isUserCampaignAllowNewProjectTemplatePickerToShow()
    else
      is_new_project_template_picker_allowed_to_show = true

    if _.isString(first_project_id = init_report.first_project_created) and is_new_project_template_picker_allowed_to_show
      Tracker.autorun (computation) ->
        active_justdo = JD.activeJustdo {lastTaskSeqId: 1}

        if not (project_id = active_justdo?._id)?
          return
        
        # Unlikely to happen, but in case someone created a project then immidiately go to another project, stop this computation.
        if project_id isnt first_project_id
          computation.stop()
          return
        
        # If project is already created with tasks, do not show the picker
        # (First task upon project creation is handled above)
        if active_justdo?.lastTaskSeqId isnt 0
          computation.stop()
          return

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