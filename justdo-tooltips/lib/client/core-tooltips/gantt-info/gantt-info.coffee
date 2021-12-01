APP.justdo_tooltips.registerTooltip
  id: "gantt-info"
  template: "gantt_info_tooltip"

Template.gantt_info_tooltip.helpers
  message: ->
    return @options.message
