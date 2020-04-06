Template.justdo_grid_gantt_controller.onRendered ->
  from = moment(APP.justdo_grid_gantt.epoch_time_from_rv.get())
  $("#grind_dantt_controller_from").val(from.format("YYYY-MM-DD"))
  to = moment.utc(APP.justdo_grid_gantt.epoch_time_to_rv.get())
  $("#grind_dantt_controller_to").val(to.format("YYYY-MM-DD"))
  return

Template.justdo_grid_gantt_controller.events
  "change #grind_dantt_controller_from": (e, tpl) ->
    APP.justdo_grid_gantt.epoch_time_from_rv.set(APP.justdo_grid_gantt.dateStringToEpoch(e.target.value))
    return

  "change #grind_dantt_controller_to": (e, tpl) ->
    APP.justdo_grid_gantt.epoch_time_to_rv.set(APP.justdo_grid_gantt.dateStringToEndOfDayEpoch(e.target.value))
    return