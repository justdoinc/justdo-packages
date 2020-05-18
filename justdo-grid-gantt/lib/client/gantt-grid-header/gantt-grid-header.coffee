Template.justdo_grid_gantt_header.onCreated ->
  @scale_rv = new ReactiveVar ("Days")
  return
Template.justdo_grid_gantt_header.helpers
  scale: ->
    return Template.instance().scale_rv.get()
  
  zz: ->
    range = APP.justdo_grid_gantt.epochRange()
    from = moment(range[0]).format("YYYY-MM-DD")
    to = moment(range[1]).format("YYYY-MM-DD")
    return "#{from}  - #{to} #{APP.justdo_grid_gantt.columnWidth()}"

Template.justdo_grid_gantt_header.events
  "click .grid-gantt-zoom-in": (e, tpl) ->
    APP.justdo_grid_gantt.zoomIn()
    return
  
  "click .grid-gantt-zoom-out": (e, tpl) ->
    APP.justdo_grid_gantt.zoomOut()
    return