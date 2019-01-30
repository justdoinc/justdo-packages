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
    if @_meetings_menu_view?
      Blaze.remove @_meetings_menu_view
      @_meetings_menu_view = null

    # TODO check whether meetings_module is enabled for this project, if not
    # don't initialize the UI

    target_element = $(target_element)
    target_parent = target_element.parent()[0]

    @_meetings_menu_view = Blaze.renderWithData(
      Template.meetings_meetings_menu,
      { project_id: project_id },
      target_parent,
      target_element[0]
    )

  removeMeetingsMenu: ->
    if @_meetings_menu_view?
      Blaze.remove @_meetings_menu_view
      @_meetings_menu_view = null

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
