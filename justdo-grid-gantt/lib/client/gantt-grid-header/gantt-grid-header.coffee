Template.justdo_grid_gantt_header.onCreated ->
  @scale_type = new ReactiveVar "days"
  @disable_zoom_in = new ReactiveVar false

  @gc = @data.gc

  # Update Dates
  @updateDates = (from, to) ->
    from = moment(from).format("YYYY-MM-DD")
    to = moment(to).format("YYYY-MM-DD")
    from_epoch = APP.justdo_grid_gantt.dateStringToStartOfDayEpoch(from)
    to_epoch = APP.justdo_grid_gantt.dateStringToEndOfDayEpoch(to)
    APP.justdo_grid_gantt.setEpochRange [from_epoch, to_epoch]
    return

  # Switch to Days
  @switchToDays = (from = APP.justdo_grid_gantt.epochRange()[0], to = APP.justdo_grid_gantt.epochRange()[1]) ->
    from = moment(from).format("YYYY-MM-DD")
    to = moment(to).format("YYYY-MM-DD")
    @updateDates(from, to)
    @scale_type.set "days"
    return

  # Switch to Weeks
  @switchToWeeks = (from = APP.justdo_grid_gantt.epochRange()[0], to = APP.justdo_grid_gantt.epochRange()[1]) ->
    # Move "from" to the last monday and "to" to the next sunday
    from = moment(from).startOf("isoWeek").format("YYYY-MM-DD")
    to = moment(to).endOf("isoWeek").format("YYYY-MM-DD")
    @updateDates(from, to)
    @scale_type.set "weeks"
    return

  # Switch to Months
  @switchToMonths = (from = APP.justdo_grid_gantt.epochRange()[0], to = APP.justdo_grid_gantt.epochRange()[1]) ->
    from = moment(from).startOf("month").format("YYYY-MM-DD")
    to = moment(to).endOf("month").format("YYYY-MM-DD")
    @updateDates(from, to)
    @scale_type.set "months"
    return

  @width_per_day_rv = new ReactiveVar(0)
  @available_width = 0
  @extra_days_to_add_to_each_scale_side = 1
  @autorun =>
    gantt_coloumn_from_epoch_time = APP.justdo_grid_gantt.epochRange()[0]
    gantt_coloumn_to_epoch_time = APP.justdo_grid_gantt.epochRange()[1]

    original_days_amount =
      Math.floor((gantt_coloumn_to_epoch_time - gantt_coloumn_from_epoch_time + 1) / 1000 / 60 / 60 / 24)

    @available_width = $(".grid-gantt-floating-elements-container", Template.instance().gc.container).outerWidth()

    @width_per_day_rv.set((1000 * 60 * 60 * 24) / (gantt_coloumn_to_epoch_time - gantt_coloumn_from_epoch_time) * @available_width) # We divide against the original to keep the same propotion, regardless of size available to viewport

    return

  @addExtraDays = => @scale_type.get() == "days"

  return


Template.justdo_grid_gantt_header.helpers
  scaleType: ->
    return Template.instance().scale_type.get()

  daysInterval: ->
    tpl = Template.instance()
    days = []

    gantt_coloumn_from_epoch_time = APP.justdo_grid_gantt.epochRange()[0]
    gantt_coloumn_to_epoch_time = APP.justdo_grid_gantt.epochRange()[1]

    from = moment.utc(gantt_coloumn_from_epoch_time)
    to = moment.utc(gantt_coloumn_to_epoch_time)

    if tpl.addExtraDays()
      from.subtract(tpl.extra_days_to_add_to_each_scale_side, "days")
      to.add(tpl.extra_days_to_add_to_each_scale_side, "days")

    while from < to
      days.push from.format("YYYY-MM-DD")
      from = from.add(1, "days")
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

  getScaleWidth: ->
    tpl = Template.instance()

    if tpl.addExtraDays()
      return tpl.available_width + ((tpl.width_per_day_rv.get() * tpl.extra_days_to_add_to_each_scale_side) * 2) + "px"

    return "auto"

  getGanttScaleOffset: ->
    tpl = Template.instance()
    grid_gantt = APP.justdo_grid_gantt
    
    epoch_from = APP.justdo_grid_gantt.epochRange()[0]
    epoch_to = APP.justdo_grid_gantt.epochRange()[1]
    
    epoch_range = [ epoch_from, epoch_to]
    
    from = moment.utc(epoch_from)
    if tpl.addExtraDays()
      from.subtract(tpl.extra_days_to_add_to_each_scale_side, "days")
    from = from.format("YYYY-MM-DD")
    from = grid_gantt.dateStringToStartOfDayEpoch from
    offset = grid_gantt.timeOffsetPixels epoch_range, from.valueOf(), tpl.available_width
    return offset
    

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
    from = APP.justdo_grid_gantt.epochRange()[0]
    to = APP.justdo_grid_gantt.epochRange()[1]
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
    from = APP.justdo_grid_gantt.epochRange()[0]
    to = APP.justdo_grid_gantt.epochRange()[1]
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
