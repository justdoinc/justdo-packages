Template.meetings_meeting_header.helpers
  meetings: ->
    APP.meetings_manager_plugin.meetings_manager.meetings.find
      project_id: @project_id

  when: (date) ->
    if(date?)
      return moment(date).format("D MMM YYYY")
    return "no set"
