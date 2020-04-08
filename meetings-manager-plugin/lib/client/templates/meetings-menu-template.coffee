Template.meetings_meetings_menu.onCreated ->
  APP.meetings_manager_plugin.meetings_manager.subscribeToMeetingsList @data.project_id


Template.meetings_meetings_menu.onRendered ->

  # Scroll event for .meetings-menu
  # On scroll show fixed section with current section title
  last_scroll_top = 0
  fixed_section_title = $(".meetings-menu-title span")

  $(".meetings-menu-list").on "scroll", ->
    st = $(this).scrollTop()
    scroll_up = false

    if st > last_scroll_top
      $(".meetings-menu-title").show()
      scroll_up = false
    else
      scroll_up = true

    last_scroll_top = st

    if last_scroll_top == 0
      $(".meetings-menu-title").hide()

    section_title = $(this).find(".meetings-menu-section-title")
    section_title.each (index) ->
      title_position = $(this).position().top
      if scroll_up
        if title_position > 25 and title_position < 35
          fixed_section_title.html $(section_title[index - 1]).html()
      else
        if title_position > 0 and title_position < 25
          fixed_section_title.html $(section_title[index]).html()


Template.meetings_meetings_menu.helpers
  meetings: (status) ->
    # APP.meetings_manager_plugin.meetings_manager.meetings.find
    #   project_id: @project_id
    meetings = APP.meetings_manager_plugin.meetings_manager.meetings.find({"project_id":@project_id, "status":status}).fetch()
    meetings = {
      "exist": meetings.length,
      "meetings": meetings
      }
    return meetings

  meetingsExist: ->
    meetings = APP.meetings_manager_plugin.meetings_manager.meetings.find({"project_id": @project_id}).fetch()
    return meetings?.length


Template.meetings_meetings_menu.events
  "click .meetings-menu-new": (e, tmpl) ->
    e.preventDefault()

    name = 'Untitled Meeting'
    project_id = tmpl.data.project_id

    APP.meetings_manager_plugin.meetings_manager.createMeeting
      title: name
      project_id: project_id
      status: "draft"
    , (err, meeting_id) ->
      if err?
        console.log err
        JustdoSnackbar.show
          text: "Internal Server Error. Please try again."
        return

      APP.meetings_manager_plugin.renderMeetingDialog(meeting_id)
      return
    return


  "click .meetings-menu-item": (e, tmpl) ->
    meeting_id = @_id
    APP.meetings_manager_plugin.renderMeetingDialog(meeting_id)
    return
