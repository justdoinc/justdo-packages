Template.meetings_meetings_menu.onCreated ->
  @meeting_search_keyword = new ReactiveVar ""

  @setMeetingSearchKeyword = (keyword=null) ->
    if (not _.isString(keyword)) or (_.isString(keyword) and keyword.trim() == "")
      keyword = ""
    else
      keyword = keyword.trim()

    @meeting_search_keyword.set(keyword)
    return


Template.meetings_meetings_menu.onRendered ->
  self = @
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

  $(".meetings-menu").on "show.bs.dropdown", ->
    if not self.meetings_list_sub?
      self.meetings_list_sub = APP.meetings_manager_plugin.meetings_manager.subscribeToMeetingsList JD.activeJustdo({_id: 1})._id
    return
  
  $(".meetings-menu").on "hidden.bs.dropdown", ->
    if self.meetings_list_sub?
      self.meetings_list_sub.stop()
      self.meetings_list_sub = null
    return 
  
Template.meetings_meetings_menu.onDestroyed ->
  if @meetings_list_sub?
    @meetings_list_sub.stop()
    @meetings_list_sub = null
  return

Template.meetings_meetings_menu.helpers
  meetings: (status) ->
    search_keyword = Template.instance().meeting_search_keyword.get()
    meetings = APP.meetings_manager_plugin.meetings_manager.meetings.find({"project_id": JD.activeJustdo({_id: 1})._id, "status":status}).fetch()

    filtered_meetings = []
    for meeting in meetings
      if RegExp(JustdoHelpers.escapeRegExp(search_keyword), "i").test(meeting.title)
        filtered_meetings.push meeting

    meetings = {
      "exist": filtered_meetings.length,
      "meetings": filtered_meetings
    }

    return meetings


Template.meetings_meetings_menu.events
  "click .meetings-menu-schedule": (e, tmpl) ->
    e.preventDefault()

    name = 'Untitled Meeting'
    project_id = JD.activeJustdo({_id: 1})._id

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

  "click .meetings-menu-start": (e, tmpl) ->
    e.preventDefault()

    name = 'Untitled Meeting'
    project_id = JD.activeJustdo({_id: 1})._id

    APP.meetings_manager_plugin.meetings_manager.createMeeting
      title: name
      project_id: project_id
      date: new Date()
      time: "" + new Date()
      status: "in-progress"
    , (err, meeting_id) ->
      APP.meetings_manager_plugin.renderMeetingDialog(meeting_id)

      return
    
    return

  "click .meetings-menu-item": (e, tmpl) ->
    meeting_id = @_id
    APP.meetings_manager_plugin.renderMeetingDialog(meeting_id)
    return

  "change .meeting-search-input, keyup .meeting-search-input": (e, tmpl) ->
    tmpl.setMeetingSearchKeyword($(e.target).val())
    return

  "mouseup .btn-meeting-menu": (e, tmpl) ->
    Meteor.defer ->
      # Focus the search input when dropdown is opened
      if $(".meeting-search-input").is(":visible")
        $(".meeting-search-input").val("").trigger("change")
        $(".meeting-search-input").focus()
      return
    return
