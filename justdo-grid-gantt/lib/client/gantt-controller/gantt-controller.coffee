Template.justdo_grid_gantt_controller.onRendered ->
  from = moment(APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get())
  $("#grind_gantt_controller_from").val(from.format("YYYY-MM-DD"))
  to = moment.utc(APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get())
  $("#grind_gantt_controller_to").val(to.format("YYYY-MM-DD"))
  return

Template.justdo_grid_gantt_controller.events
  "change #grind_gantt_controller_from": (e, tpl) ->
    APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.set(APP.justdo_grid_gantt.dateStringToStartOfDayEpoch(e.target.value))
    return

  "change #grind_gantt_controller_to": (e, tpl) ->
    APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.set(APP.justdo_grid_gantt.dateStringToEndOfDayEpoch(e.target.value))
    return