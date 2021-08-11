_.extend MeetingsManagerPlugin.prototype,
  autorun: (cb) ->
    @_computations = @_computations || []
    @_computations.push (autorun = Tracker.autorun(cb))

    return autorun

  renderMeetingDialog: (meeting_id) ->
    if @_meeting_dialog_view?
      Blaze.remove @_meeting_dialog_view
      @_meeting_dialog_view = null

    @_meeting_dialog_view = Blaze.renderWithData(
      Template.meetings_meeting_dialog,
      { meeting_id: meeting_id },
      $('body')[0]
    )

  removeMeetingDialog: ->
    if @_meeting_dialog_view?
      Blaze.remove @_meeting_dialog_view
      @_meeting_dialog_view = null

  renderMeetingsMenu: (project_id, target_element) ->
    JD.registerPlaceholderItem "meetings-menu",
      data:
        template: "meetings_meetings_menu"
        template_data:
          project_id: project_id

      domain: "project-right-navbar"
      position: 360

    return

  removeMeetingsMenu: ->
    JD.unregisterPlaceholderItem "meetings-menu"

    return

  registerConfigTemplate: ->
    # adding meeting to the project configuration:

    APP.executeAfterAppLibCode ->
      module = APP.modules.project_page

      module.project_config_ui.registerConfigTemplate "meetings_config",
        section: "extensions"
        template: "meetings_config"
        priority: 1000

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    if @_computations
      _.each @_computations, (comp) -> comp.stop()

    @destroyed = true

    @logger.debug "Destroyed"

    return

  setupContextMenu: ->
    self = @

    APP.justdo_tasks_context_menu.registerMainSection "meetings",
      position: 350
      data:
        label: "Meetings"
      listingCondition: ->
        return APP.modules.project_page.curProj()?.isCustomFeatureEnabled("meetings_module")

    APP.justdo_tasks_context_menu.registerSectionItem "meetings", "start-meeting",
      position: 100
      data:
        label: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          return "Start a meeting"
        op: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          task = APP.collections.Tasks.findOne task_id
          APP.meetings_manager_plugin.meetings_manager.createMeeting
            title: task.title
            project_id: task.project_id
            date: new Date()
            time: "" + new Date()
            status: "in-progress"
          , (err, meeting_id) ->
            APP.meetings_manager_plugin.meetings_manager.addTaskToMeeting meeting_id, { task_id: task_id }

            APP.meetings_manager_plugin.renderMeetingDialog(meeting_id)

            return

          return 
        icon_type: "feather"
        icon_val: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
          return "plus"
      listingCondition: (item_definition, task_id, task_path, field_val, dependencies_fields_vals, field_info) ->
        return true
  
  openSettingsDialog: ->
    message_template =
      APP.helpers.renderTemplateInNewNode(Template.meetings_settings, {})

    bootbox.dialog
      title: "Meeting Settings"
      message: message_template.node
      animate: false
      className: "meetings-settings-dialog bootbox-new-design"

      onEscape: ->
        return true

      buttons:
        submit:
          label: "Close"
          callback: =>
            return true
    
    return