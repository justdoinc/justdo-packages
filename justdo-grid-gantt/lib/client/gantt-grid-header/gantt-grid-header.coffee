Template.justdo_grid_gantt_header.onCreated ->
  @scale_type = new ReactiveVar "days"
  @disable_zoom_in = new ReactiveVar false

  # Update Dates
  @updateDates = (from, to) ->
    from = moment(from).format("YYYY-MM-DD")
    to = moment(to).format("YYYY-MM-DD")
    APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.set(APP.justdo_grid_gantt.dateStringToStartOfDayEpoch(from))
    APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.set(APP.justdo_grid_gantt.dateStringToEndOfDayEpoch(to))
    return

  # Switch to Days
  @switchToDays = (from = APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get(), to = APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get()) ->
    from = moment(from).format("YYYY-MM-DD")
    to = moment(to).format("YYYY-MM-DD")
    @updateDates(from, to)
    @scale_type.set "days"
    return

  # Switch to Weeks
  @switchToWeeks = (from = APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get(), to = APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get()) ->
    # Move "from" to the last monday and "to" to the next sunday
    from = moment(from).startOf("isoWeek").format("YYYY-MM-DD")
    to = moment(to).endOf("isoWeek").format("YYYY-MM-DD")
    @updateDates(from, to)
    @scale_type.set "weeks"
    return

  # Switch to Months
  @switchToMonths = (from = APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get(), to = APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get()) ->
    from = moment(from).startOf("month").format("YYYY-MM-DD")
    to = moment(to).endOf("month").format("YYYY-MM-DD")
    @updateDates(from, to)
    @scale_type.set "months"
    return

  return


Template.justdo_grid_gantt_header.helpers
  scaleType: ->
    return Template.instance().scale_type.get()

  daysInterval: ->
    days = []
    from = moment(APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get())
    to = moment(APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get())

    while from < to
      days.push moment(from).format("YYYY-MM-DD")
      from = moment(from).add(1, "days")
    return days

  getDateNumber: (date) ->
    return moment(date).date()

  isWeekend: (date) ->
    if moment(date).day() == 0 or moment(date).day() == 6
      return true

  isFirstOfMonth: (date) ->
    firstDayOfMonth = moment(date).startOf("month").format("YYYY-MM-DD")
    if moment(date).format("YYYY-MM-DD") == firstDayOfMonth
      return true

  isToday: (date) ->
    if moment(date).isSame(new Date(), "d")
      return true

  isStartOfWeek: (date) ->
    if moment(date).day() == 1
      return true

  getYear: (date) ->
    return moment(date).year()

  getMonth: (date) ->
    return moment(date).format('MMMM')

  getWeek: (date) ->
    return moment(date).week()

  getDateColspanMonth: (date) ->
    colspan = moment(date).daysInMonth()
    return colspan

  disableZoomIn: ->
    return Template.instance().disable_zoom_in.get()


Template.justdo_grid_gantt_header.events
  "click .grid-gantt-scale-months": (e, tmpl) ->
    from = moment().add(-16, "days").startOf("month")
    to = moment().add(16, "days").endOf("month")
    tmpl.switchToMonths(from, to)
    return

  "click .grid-gantt-scale-weeks": (e, tmpl) ->
    from = moment().add(-5, "days")
    to = moment().add(5, "days")
    tmpl.switchToWeeks(from, to)
    return

  "click .grid-gantt-scale-days": (e, tmpl) ->
    from = moment().add(-5, "days")
    to = moment().add(5, "days")
    tmpl.switchToDays(from, to)
    return

  "click .grid-gantt-zoom-in": (e, tmpl) ->
    scaleType = tmpl.scale_type.get()
    from = APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get()
    to = APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get()
    diff = moment(to).add(-1, "days").diff(moment(from), "days")
    td_width = $(".grid-gantt-scale-table td").width()

    if scaleType == "days"
      from = moment(from).add(1, "days")
      to = moment(to).add(-2, "days")
      tmpl.updateDates(from, to)

      if diff <= 7 # Disable "zoom-in" button
        tmpl.disable_zoom_in.set true

    if scaleType == "weeks"
      if diff <= 19
        tmpl.switchToDays()
      else
        from = moment(from).add(7, "days")
        to = moment(to).add(-8, "days")
        tmpl.updateDates(from, to)

    if scaleType == "months"
      if diff < 60
        tmpl.switchToWeeks()
      else
        from = moment(from).add(1, "months")
        to = moment(to).add(-1, "months").add(-1, "days")
        tmpl.updateDates(from, to)

    return

  "click .grid-gantt-zoom-out": (e, tmpl) ->
    scaleType = tmpl.scale_type.get()
    from = APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get()
    to = APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get() # Added One Day???
    diff = moment(to).add(-1, "days").diff(moment(from), "days")
    td_width = $(".grid-gantt-scale-table td").width()

    if scaleType == "days"
      if diff >= 5
        tmpl.disable_zoom_in.set false

      if td_width < 20
        tmpl.switchToWeeks()
      else
        from = moment(from).add(-1, "days")
        to = moment(to)
        tmpl.updateDates(from, to)

    if scaleType == "weeks"
      if td_width < 60
        tmpl.switchToMonths()
      else
        from = moment(from).add(-7, "days")
        to = moment(to).add(6, "days")
        tmpl.updateDates(from, to)

    if scaleType == "months"
      from = moment(from).add(-1, "months")
      to = moment(to).add(1, "months").add(-1, "days")
      tmpl.updateDates(from, to)

    return
