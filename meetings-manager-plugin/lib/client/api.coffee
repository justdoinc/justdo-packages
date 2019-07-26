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
    APP.modules.project_page.registerPlaceholderItem "meetings-menu",
      data:
        template: "meetings_meetings_menu"
        template_data:
          project_id: project_id

      domain: "project-right-navbar"
      position: 360

    return

  removeMeetingsMenu: ->
    APP.modules.project_page.unregisterPlaceholderItem "meetings-menu"

    return

  registerConfigTemplate: ->
    # adding meeting to the project configuration:

    APP.executeAfterAppLibCode ->
      module = APP.modules.project_page

      module.project_config_ui.registerConfigTemplate "meetings_config",
        section: "extensions"
        template: "meetings_config"
        priority: 100

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    if @_computations
      _.each @_computations, (comp) -> comp.stop()

    @destroyed = true

    @logger.debug "Destroyed"

    return
