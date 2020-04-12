meetings_manager = null

Template.task_pane_meetings_manager_section.onCreated ->
  # Wait to set this var till the meetings_manager has loaded.
  # Once loaded it won't change.

  meetings_manager = APP.meetings_manager_plugin.meetings_manager

  @autorun ->
    task_id = APP.modules.project_page.activeItemId()
    meetings_manager.subscribeToNotesForTask task_id
    meetings_manager.subscribeToPrivateNotesForTask task_id
    meetings_manager.subscribeToMeetingsForTask task_id


Template.task_pane_meetings_manager_section.helpers

  meetings: (status) ->
    meetings = meetings_manager.meetings.find({"status": status}).fetch()
    task_id = APP.modules.project_page.activeItemId()

    meetings = _.filter meetings, (meeting) ->
      found_meeting = meetings_manager.meetings_tasks.findOne
        meeting_id: meeting._id
        task_id: task_id
      return found_meeting?

    meetings = {
      "exist": meetings.length,
      "meetings": _.sortBy(meetings, "updatedAt").reverse()
      }

    return meetings

  meetingsExist: ->
    meetings = meetings_manager.meetings.find().fetch()
    task_id = APP.modules.project_page.activeItemId()

    meetings = _.filter meetings, (meeting) ->
      found_meeting = meetings_manager.meetings_tasks.findOne
        meeting_id: meeting._id
        task_id: task_id
      return found_meeting?

    return meetings?.length



Template.task_pane_meetings_manager_section.events
  'click .meetings-toolbar-create': (e, tmpl) ->
    e.preventDefault()

    task_id = APP.modules.project_page.activeItemId()
    task = APP.collections.Tasks.findOne task_id

    # TODO: Loading indicator?

    meetings_manager.createMeeting
      title: "Ad-Hoc Re: " + task.title
      project_id: task.project_id
      date: new Date()
      time: "" + new Date()
      status: "in-progress"
    , (err, meeting_id) ->

      # TODO handle any error from addTaskToMeeting
      meetings_manager.addTaskToMeeting meeting_id, { task_id: task_id }

      APP.meetings_manager_plugin.renderMeetingDialog(meeting_id)


  # "click .meeting_header .meeting .title, click .meeting .aside": (e, tmpl) ->
  #   APP.meetings_manager_plugin.renderMeetingDialog @_id
  #
  # "click .note .aside": (e, tmpl) ->
  #   APP.meetings_manager_plugin.renderMeetingDialog @meeting_id
