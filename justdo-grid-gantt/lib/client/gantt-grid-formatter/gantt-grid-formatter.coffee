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
        current_val = [APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get(), APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get()]
        cached_val = @getCurrentColumnData("column_start_end") or [0, 0]# non reactive

        if current_val[0] != cached_val[0] or current_val[1] != cached_val[1]
          @setCurrentColumnData("column_start_end", current_val)
          dep.changed()
        return

    Tracker.onInvalidate ->
      column_width_changed_comp.stop()
      column_start_end_changed_comp.stop()
      APP.justdo_grid_gantt?.is_gantt_column_displayed_rv.set false
      return


    return

  slick_grid: ->
    {doc} = @getFriendlyArgs()
    
    if not (cached_info = JustdoHelpers.sameTickCacheGet("column_info"))?
      column_start_end = [0, 0]
      if not (column_start_end = @getCurrentColumnData("column_start_end"))?
        column_start_end = [APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get(), APP.justdo_grid_gantt.gantt_coloum_to_epoch_time_rv.get()]
      column_width_px = @getCurrentColumnData("column_width")
      JustdoHelpers.sameTickCacheSet("column_info", [column_start_end, column_width_px])
    else
      column_start_end = cached_info[0]
      column_width_px = cached_info[1]
      
    column_start_epoch = column_start_end[0]
    column_end_epoch = column_start_end[1]
    
    if not (task_info = APP.justdo_grid_gantt.task_id_to_info[doc._id])?
      return "no task info"
      
    ############
    # main block
    ############
    main_bar_mark = ""
    if (self_start_time = task_info.self_start_time)? and
        (self_end_time = task_info.self_end_time)? and
        self_start_time < self_end_time
      
      #check if block within column range
      if (self_start_time >= column_start_epoch and self_start_time <= column_end_epoch) or # start time within range
          (self_end_time >= column_start_epoch and self_end_time<= column_end_epoch) or # end time within range
          (self_start_time < column_start_epoch and self_end_time > column_end_epoch) # starts before and ends after
        
        bar_start_px = 0
        bar_end_px = column_width_px
        if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, self_start_time, column_width_px))?
          bar_start_px = offset
        if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, self_end_time, column_width_px))?
          bar_end_px = offset
          
        main_bar_mark = """<div class="gantt-main-bar" style="left:#{bar_start_px}px; width:#{bar_end_px - bar_start_px}px"></div>"""
    ############
    # earliest child
    ############
    earliest_child_mark = ""
    if (earliest_child = task_info.earliest_child_start_time)?
      if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, earliest_child, column_width_px))?
        earliest_child_mark = """<div class="gantt-earliest-child" style="left:#{offset}px"></div>"""
  
    ############
    # latest child
    ############
    latest_child_mark = ""
    if (latest_child = task_info.latest_child_end_time)?
      if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, latest_child, column_width_px))?
        latest_child_mark = """<div class="gantt-latest-child" style="left:#{offset - 8}px"></div>"""
  
    ############
    # due date
    ############
    due_date_mark = ""
    if (milestone_time = task_info.milestone_time)?
      if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, milestone_time, column_width_px))?
        due_date_mark = """<div class="gantt-milestone" style="left:#{offset - 5}px"></div>"""  #the -5 here is needed due to rotation

    formatter = """
      <div class="grid-formatter grid-gantt-formatter">
        #{main_bar_mark}
        #{earliest_child_mark}
        #{latest_child_mark}
        #{due_date_mark}
      </div>
    """
    return formatter
  # return "When this # change I am being re-rendered: " + Math.ceil(Math.random() * 1000) + "; My width is: " + @getCurrentColumnData("column_width")

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
