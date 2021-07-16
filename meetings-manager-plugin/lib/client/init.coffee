_.extend MeetingsManagerPlugin.prototype,
  _immediateInit: ->

    return

  _deferredInit: ->

    @registerConfigTemplate()

    _meetings_menu_view = null

    project_id = null

    @autorun (computation) =>
      project = APP.modules.project_page.curProj()

      if project

        if not project.isCustomFeatureEnabled("meetings_module")
          @removeMeetingsMenu()
          @removeMeetingDialog()
          return

        if project.id != project_id
          @removeMeetingDialog()

        project_id = project.id

        Tracker.autorun (c) =>

          # XXX This inner autorun is a HACK
          # Instead we should find out how to know when the search control has
          # rendered
          item = APP.modules.project_page.activeItemObj()

          target_element = $(".required-actions-dropdown-container")

          if target_element.length == 0
            return

          c.stop()

          @renderMeetingsMenu project.id, target_element[0]

      else
        @removeMeetingDialog()

      computation.onStop =>
        @removeMeetingsMenu()

    @registerTaskPaneSection()
    @setupContextMenu()
    
    return
