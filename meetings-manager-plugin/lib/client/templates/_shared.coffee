Template.meetings_status_indicator.helpers
  color: ->
    if @status == "draft"
      return "gray"
    if @status == "pending"
      return "orange"
    if @status == "in-progress"
      return "green"
    if @status == "adjourned"
      return "black"
    if @status == "cancelled"
      return "red"

    return ""

  title: ->
    @status.charAt(0).toUpperCase() + status.slice(1)
