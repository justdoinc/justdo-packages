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
      console.log ">>> in formatter" # Daniel - this is called twice when switching to a JustDo with the column on. Why?
      APP.justdo_grid_gantt?.is_gantt_column_displayed_rv.set true
  
      # Run in an isolated reactivity scope
      column_width_changed_comp = Tracker.autorun =>
        current_val = _.find(@getViewReactive(), (field) => field.field == @getColumnFieldId())?.width # Reactive
        cached_val = @getCurrentColumnData("column_width") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("column_width", current_val)
          dep.changed()
        return

      column_start_end_changed_comp = Tracker.autorun =>
        current_val = [APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get(), APP.justdo_grid_gantt.gantt_coloum_to_epoch_time_rv.get()]
        cached_val = @getCurrentColumnData("column_start_end") or [0, 0]# non reactive

        if current_val[0] != cached_val[0] or current_val[1] != cached_val[1]
          @setCurrentColumnData("column_start_end", current_val)
          dep.changed()
        return

    Tracker.onInvalidate ->
      column_width_changed_comp.stop()
      column_start_end_changed_comp.stop()
      APP.justdo_grid_gantt?.is_gantt_column_displayed_rv.set false
      console.log "<<< out formatter"
      return


    return

  slick_grid: ->
    {path, doc, row} = @getFriendlyArgs()
    console.log @getFriendlyArgs()
    if doc._id == "4Cqzm8wwqPSTx52zo"
      console.log ">>>>", @getFriendlyArgs().grid_data.grid_tree[row]
    
    return
    
    
    column_start_end = [0, 0]
    if not (column_start_end = @getCurrentColumnData("column_start_end"))?
      column_start_end = [APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get(), APP.justdo_grid_gantt.gantt_coloum_to_epoch_time_rv.get()]

    column_start_epoch = column_start_end[0]
    column_end_epoch = column_start_end[1]
    column_width_px = @getCurrentColumnData("column_width")

    ############
    # main bar
    ############
    main_bar_mark = ""
    start_epoch = 0
    end_epoch = 0

    if doc.start_date?
      start_epoch = APP.justdo_grid_gantt.dateStringToStartOfDayEpoch doc.start_date
      if doc.end_date?
        end_epoch = APP.justdo_grid_gantt.dateStringToEndOfDayEpoch doc.end_date
        if doc.due_date? and doc.due_date == doc.end_date
          end_epoch = APP.justdo_grid_gantt.dateStringToMidDayEpoch doc.end_date
      else if doc.due_date?
        end_epoch = APP.justdo_grid_gantt.dateStringToMidDayEpoch doc.due_date
      else
        end_epoch = APP.justdo_grid_gantt.dateStringToEndOfDayEpoch doc.start_date
    else if doc.end_date?
      end_epoch = APP.justdo_grid_gantt.dateStringToEndOfDayEpoch doc.end_date
      start_epoch = APP.justdo_grid_gantt.dateStringToStartOfDayEpoch doc.end_date
      
      
#    else
#      today = moment().format("YYYY-MM-DD")
#      start_epoch = APP.justdo_grid_gantt.dateStringToStartOfDayEpoch today
#      end_epoch = APP.justdo_grid_gantt.dateStringToEndOfDayEpoch today

    #check if bar within column range
    if (start_epoch >= column_start_epoch and start_epoch <= column_end_epoch) or
        (end_epoch >= column_start_epoch and end_epoch<= column_end_epoch)
      bar_start_px = 0
      if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, start_epoch, column_width_px))?
        bar_start_px = offset
      bar_end_px = column_width_px
      if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, end_epoch, column_width_px))?
        bar_end_px = offset
      main_bar_mark = """<div class="gantt-main-bar" style="left:#{bar_start_px}px; width:#{bar_end_px - bar_start_px}px"></div>"""

    ############
    # due date
    ############
    due_date_mark = ""
    if doc.due_date?
      time = APP.justdo_grid_gantt.dateStringToMidDayEpoch doc.due_date
      if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, time, column_width_px))?
        due_date_mark = """<div class="gantt-milestone" style="left:#{offset - 5}px"></div>"""  #the -5 here is needed due to rotation

    formatter = """
      <div class="grid-formatter grid-gantt-formatter">
        #{main_bar_mark}
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
