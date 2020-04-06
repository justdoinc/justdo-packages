GridControl.installFormatter JustdoGridGantt.pseudo_field_formatter_id,
  slickGridColumnStateMaintainer: ->
    # The following is responsible for full column invalidation upon column width resize.
    if not Tracker.active
      @logger.warn "slickGridColumnStateMaintainer: called outside of computation, skipping"

      return

    # Create a dependency and depend on it.
    dep = new Tracker.Dependency()
    dep.depend()

    column_width_changed_comp = null
    column_start_end_changed_comp = null
    Tracker.nonreactive =>
      # Run in an isolated reactivity scope
      column_width_changed_comp = Tracker.autorun =>
        current_val = _.find(@getViewReactive(), (field) => field.field == @getColumnFieldId())?.width # Reactive
        cached_val = @getCurrentColumnData("column_width") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("column_width", current_val)
          dep.changed()
        return

      column_start_end_changed_comp = Tracker.autorun =>
        current_val = [APP.justdo_grid_gantt.epoch_time_from_rv.get(), APP.justdo_grid_gantt.epoch_time_to_rv.get()]
        cached_val = @getCurrentColumnData("column_start_end") or [0, 0]# non reactive

        if current_val[0] != cached_val[0] or current_val[1] != cached_val[1]
          @setCurrentColumnData("column_start_end", current_val)
          dep.changed()
        return

    Tracker.onInvalidate ->
      column_width_changed_comp.stop()
      column_start_end_changed_comp.stop()
      return


    return

  slick_grid: ->
    {path, doc} = @getFriendlyArgs()
    console.log @getFriendlyArgs()
    column_start_end = [0, 0]
    if not (column_start_end = @getCurrentColumnData("column_start_end"))?
      column_start_end = [APP.justdo_grid_gantt.epoch_time_from_rv.get(), APP.justdo_grid_gantt.epoch_time_to_rv.get()]
    due_date_mark = ""
    if doc.due_date?
      time = APP.justdo_grid_gantt.dateStringToMidDayEpoch doc.due_date
      if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, time, @getCurrentColumnData("column_width")))?
        due_date_mark = """<div class="milestone" style="left:#{offset - 5}px"></div>"""  #the -5 here is needed due to rotation

    formatter = """
      <div class="grid-formatter grid-gantt-formatter">
        #{due_date_mark}


      </div>
    """
    return formatter
#    return "When this # change I am being re-rendered: " + Math.ceil(Math.random() * 1000) + "; My width is: " + @getCurrentColumnData("column_width")

  # REMINDER! REMINDER! REMINDER! as this formatter will evolve, definitions of events should be centralized
  # and not redefined for every cell separately. Below is an example from the checklist formatter

  slick_grid_jquery_events: [
  #  {
  #     args: ["click", ".checklist-field-formatter"]
  #     handler: (e) ->
  #       APP.justdo_checklist_field.toggleItemState(@, @getEventPath(e), @getEventFormatterDetails(e).field_name, allowNaOnCurrentProject())

  #       return
  #   }
  ]

  print: (doc, field, path) ->
    {grid_control, path, field} = @getFriendlyArgs()

    return ""
