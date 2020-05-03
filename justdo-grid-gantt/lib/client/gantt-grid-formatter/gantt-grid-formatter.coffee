# manage hitting escape to stop mouse operations
$("body").keyup (e) ->
  if not (e.keyCode == 27)
    return
  if (grid_gantt = APP.justdo_grid_gantt)?
    grid_gantt.resetStatesChangeOnEscape()
  return

GridControl.installFormatter JustdoGridGantt.pseudo_field_formatter_id,
  
  gridControlInit: ->
    # IMPORTANT! The following code assumes that there is only a single Gantt Field formatter in any given
    # grid control, if that will change in the future, will need to have a different approach.
    gc = @
    
    redrawFormatterHeader = (field_id) ->
      $grid_gantt_header_field = $("##{gc.getGridUid()}#{field_id}")
      
      # Beware of XSS
      header_html = """
        <div class="grid-gantt-header" style="position: absolute; top: 0; bottom: 0; left: 0; right: 0; background: beige;">
          CONTENT FROM:#{APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get()} TO:#{APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get()}; RENDER ID:#{Math.ceil(Math.random() * 1000)}
        </div>
      """
      
      $(".grid-gantt-header", $grid_gantt_header_field).remove() # Remove any existing header html
      $grid_gantt_header_field.prepend(header_html)
      $(".slick-column-name", $grid_gantt_header_field).remove()
      
      return
    
    getGanttFieldViewDef = ->
      extended_schema = gc.getSchemaExtendedWithCustomFields()
      
      view = gc.getViewReactive()
      
      for field_def in view
        if extended_schema[field_def.field].grid_column_formatter == JustdoGridGantt.pseudo_field_formatter_id
          return field_def
    
    # The following tracker takes care of requiring the grid to have double header when
    # we find a field that uses the formatter: JustdoGridGantt.pseudo_field_formatter_id
    #
    # In addition, for every view change, if we find a field that uses formatter the Gantt Field formatter
    # we call redrawFormatterHeader(field_id) with its field_id
    #
    # Again, we assume at most one field is using the Gantt Field formatter
    # double_header_requested = false
    Tracker.autorun ->
      if (field_def = getGanttFieldViewDef())?
        # if not double_header_requested # If double header requested by us already, adding another request will cause redundant extra request
        #   gc.requireDoubleHeader()
          # double_header_requested = true
        redrawFormatterHeader(field_def.field)
        return
      
      # If no Gantt Field exists in the grid
      # if double_header_requested
      #   gc.releaseDoubleHeader()
      #   double_header_requested = false
      return
    
    # The following autorun triggers redraw when the gantt settings changes
    Tracker.autorun ->
      if APP.justdo_grid_gantt.isPluginInstalledOnProjectDoc(JD.activeJustdo())
        APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get()
        APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get()
        if (field_def = getGanttFieldViewDef())?
          redrawFormatterHeader(field_def.field)
      return
    
    return
  
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
          APP.justdo_grid_gantt.refreshArrows()
        return

      column_start_end_changed_comp = Tracker.autorun =>
        current_val = [APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get(), APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get()]
        cached_val = @getCurrentColumnData("column_start_end") or [0, 0]# non reactive

        if current_val[0] != cached_val[0] or current_val[1] != cached_val[1]
          @setCurrentColumnData("column_start_end", current_val)
          APP.justdo_grid_gantt.refreshArrows()
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
        start = APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get()
        end = APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get()
        column_start_end = [start, end]
      column_width_px = @getCurrentColumnData("column_width")
      JustdoHelpers.sameTickCacheSet("column_info", [column_start_end, column_width_px])
    else
      column_start_end = cached_info[0]
      column_width_px = cached_info[1]
      
    column_start_epoch = column_start_end[0]
    column_end_epoch = column_start_end[1]
    
    if not (task_info = APP.justdo_grid_gantt.task_id_to_info[doc._id])?
      return ""
      
    ############
    # main block
    # Following gantt-pro approach - at this stage the user will be able to change the duration while dragging the end
    # and will be able to change the start-time while dragging the entire bar
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
          if offset > 0
            bar_start_px = offset
        if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, self_end_time, column_width_px))?
          if offset < column_width_px
            bar_end_px = offset
           
        date_hint = ""
        if (states = APP.justdo_grid_gantt.getState())
          # Daniel/Igor- I couldn't get the z-index to make this hint higher than the columns around it. I'll need your help w/ this one.
          if states.end_time.is_dragging
            date = JustdoHelpers.normalizeUnicodeDateStringAndFormatToUserPreference(moment.utc(self_end_time).format("YYYY-MM-DD"))
            date_hint = """
                <div class="end-date-hint">#{date}</div>
        """
        main_bar_mark = """
            <div class="gantt-main-bar" style="left:#{bar_start_px}px; width:#{bar_end_px - bar_start_px}px" task-id="#{doc._id}"></div>
            <div class="gantt-main-bar-start-drop-area" style="left:#{bar_start_px}px;"></div>
            <div class="gantt-main-bar-end-drag" style="left:#{bar_end_px - 8}px;" task-id="#{doc._id}">#{date_hint}</div>
            <div class="gantt-main-bar-F2x-dependency" style="left:#{bar_end_px}px;">
              <svg class="jd-icon gantt-main-bar-F2x-dependency-icon">
                <use xlink:href="/layout/icons-feather-sprite.svg#circle"/>
              </svg>
            </div>
        """
        
    ############
    # earliest child
    ############
    earliest_child_mark = ""
    if (earliest_child = task_info.earliest_child_start_time)?
      if earliest_child >= column_start_epoch and earliest_child <= column_end_epoch
        if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, earliest_child, column_width_px))?
          earliest_child_mark = """<div class="gantt-earliest-child" style="left:#{offset}px"></div>"""
  
    ############
    # latest child
    ############
    latest_child_mark = ""
    if (latest_child = task_info.latest_child_end_time)?
      if latest_child >= column_start_epoch and latest_child <= column_end_epoch
        if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, latest_child, column_width_px))?
          latest_child_mark = """<div class="gantt-latest-child" style="left:#{offset - 8}px"></div>"""
  
    ############
    # basket border
    ############
    basket_border_mark = ""
    if earliest_child? and latest_child?
      if (earliest_child >= column_start_epoch and earliest_child <= column_end_epoch) or # start time within range
          (latest_child >= column_start_epoch and latest_child<= column_end_epoch) or # end time within range
          (earliest_child < column_start_epoch and latest_child > column_end_epoch) # starts before and ends after
        
        box_start_px = 0
        box_end_px = column_width_px
        if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, earliest_child, column_width_px))?
          if offset > 0
            box_start_px = offset
        if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, latest_child, column_width_px))?
          if offset < column_width_px
            box_end_px = offset
  
        basket_border_mark = """<div class="gantt-basket-border" style="left:#{box_start_px}px; width:#{box_end_px - box_start_px}px"></div>"""
   
    ############
    # due date
    ############
    due_date_mark = ""
    if (milestone_time = task_info.milestone_time)?
      if (offset = APP.justdo_grid_gantt.timeOffsetPixels(column_start_end, milestone_time, column_width_px))?
        if offset >= 0 and offset <= column_width_px
          due_date_mark = """<div class="gantt-milestone" style="left:#{offset - 5}px"></div>"""  #the -5 here is needed due to rotation

    formatter = """
      <div class="grid-formatter grid-gantt-formatter" task-id="#{doc._id}">
        #{basket_border_mark}
        #{earliest_child_mark}
        #{latest_child_mark}
        #{main_bar_mark}
        #{due_date_mark}
      </div>
    """
    return formatter
    # return "When this # change I am being re-rendered: " + Math.ceil(Math.random() * 1000) + "; My width is: " + @getCurrentColumnData("column_width")

  slick_grid_jquery_events: [
    args: ["mouseenter", ".gantt-main-bar-start-drop-area"]
    handler: (e) ->
      states = APP.justdo_grid_gantt.getState()
      if states.dependencies.finish_to_x_independent?
        $(e.target).css("background-color","red")
      return
  ,
    args: ["mouseleave", ".gantt-main-bar-start-drop-area"]
    handler: (e) ->
      states = APP.justdo_grid_gantt.getState()
      if states.dependencies.finish_to_x_independent?
        $(e.target).css("background-color","")
      return
  ,
    args: ["mouseup", ".gantt-main-bar-start-drop-area"]
    handler: (e) ->
      states = APP.justdo_grid_gantt.getState()
      if (independent_id = states.dependencies.finish_to_x_independent)?
        formatter_container = e.target.closest(".grid-gantt-formatter")
        if (dependent_id = formatter_container.getAttribute("task-id"))? and
            (dependencies = APP.justdo_dependencies)?
          dependencies.addFinishToStartDependency JD.activeJustdo()._id, independent_id, dependent_id
        $(e.target).css("cursor","")
      return
  ,
    args: ["mousedown", ".gantt-main-bar-F2x-dependency-icon"]
    handler: (e) ->
      formatter_container = e.target.closest(".grid-gantt-formatter")
      if (independent_id = formatter_container.getAttribute("task-id"))?
        states = APP.justdo_grid_gantt.getState()
        states.dependencies.finish_to_x_independent = independent_id
        states.dependencies.independent_end_time = APP.justdo_grid_gantt.task_id_to_info[independent_id].self_end_time
        states.mouse_down.x = e.clientX
        states.mouse_down.y = e.clientY
        states.mouse_down.row = @getEventRow(e)
      return
  ,
    args: ["click", ".dependency-1-2-cancel-icon"]
    handler: (e) ->
      dependency_container = e.target.closest(".dependency-container")
      if (dependent = dependency_container.getAttribute("dependent-id"))? and
          (independent = dependency_container.getAttribute("independent-id"))? and
          (dependency_type = dependency_container.getAttribute("dependency-type"))? and
          (dependencies = APP.justdo_dependencies)?
        
        if dependency_type == "F2S"
          dependencies.removeFinishToStartDependency JD.activeJustdo()._id, independent, dependent
      
      return
  ,
    args: ["mousedown", ".gantt-main-bar-end-drag"]
    handler: (e) ->
      states = APP.justdo_grid_gantt.getState()
      task_id = e.target.getAttribute("task-id")
      states.task_id = task_id
      states.end_time.is_dragging = true
      states.end_time.original_time = APP.justdo_grid_gantt.task_id_to_info[task_id].self_end_time
      states.mouse_down.x = e.clientX
      states.mouse_down.y = e.clientY
      states.mouse_down.row = @getEventRow(e)
      return
  ,
    args: ["mousedown", ".slick-cell.l1"]  #Daniel - I wasn't able to add a class to the parent div of the formatter
                                            # the l1 is hard coded, and my question is how to arr/remove it as the column
                                            # location changes
    handler: (e) ->
      states = APP.justdo_grid_gantt.getState()
      if states.end_time.is_dragging
        return
      if states.dependencies.finish_to_x_independent?
        return
      states.mouse_down.x = e.clientX
      states.mouse_down.y = e.clientY
      states.column_range.is_dragging = true
      states.column_range.original_from_epoch_time = APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get()
      states.column_range.original_to_epoch_time = APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get()
      return
  ,
    # note - this is a catch all for mouse up
    args: ["mouseup", ".slick-viewport"]
    handler: (e) ->
      states = APP.justdo_grid_gantt.getState()
      if states.end_time.is_dragging
        if Math.abs(e.clientX - states.mouse_down.x) > 5
          delta_time = APP.justdo_grid_gantt.pixelsDeltaToEpochDelta e.clientX - states.mouse_down.x
        else
          delta_time = 0
        
        new_end_epoch = states.end_time.original_time + delta_time
        new_end_date = moment.utc(new_end_epoch).format("YYYY-MM-DD")
        
        JD.collections.Tasks.update states.task_id,
          $set:
            end_date: new_end_date
            
        states.end_time.is_dragging = false
        APP.justdo_grid_gantt.setPresentationEndTime states.task_id, APP.justdo_grid_gantt.dateStringToEndOfDayEpoch new_end_date
        states.task_id = null
        
      if states.column_range.is_dragging
        states.column_range.is_dragging = false
        
      if states.dependencies.finish_to_x_independent?
        states.dependencies.finish_to_x_independent = null
        
      return
  ,
    # note - this is a catch all for mouse move
    args: ["mousemove", ".slick-viewport"]
    handler: (e) ->
      if not (states = APP.justdo_grid_gantt.getState())?
        return
        
      if states.end_time.is_dragging
        if Math.abs(e.clientX - states.mouse_down.x) > 5
          delta_time = APP.justdo_grid_gantt.pixelsDeltaToEpochDelta e.clientX - states.mouse_down.x
        else
          delta_time = 0
        
        APP.justdo_grid_gantt.setPresentationEndTime states.task_id, states.end_time.original_time + delta_time
        
      else if states.column_range.is_dragging
        delta_time = APP.justdo_grid_gantt.pixelsDeltaToEpochDelta e.clientX - states.mouse_down.x
        APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.set states.column_range.original_from_epoch_time - delta_time
        APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.set states.column_range.original_to_epoch_time - delta_time
        
      else if states.dependencies.finish_to_x_independent?
        epoch_range = [
          APP.justdo_grid_gantt.gantt_coloumn_from_epoch_time_rv.get(),
          APP.justdo_grid_gantt.gantt_coloumn_to_epoch_time_rv.get()
        ]
        gc = APP.modules.project_page.mainGridControl()
        
        # Daniel - I'll need some help here as it's not really working
        
        delta_time = APP.justdo_grid_gantt.pixelsDeltaToEpochDelta e.clientX - states.mouse_down.x
        independent_end_x = APP.justdo_grid_gantt.timeOffsetPixels(epoch_range, states.dependencies.independent_end_time, APP.justdo_grid_gantt.grid_gantt_column_width )
        independent_end_y = gc._grid.getRowTopPosition(states.mouse_down.row) + 15
        line_end_x = APP.justdo_grid_gantt.timeOffsetPixels(epoch_range, states.dependencies.independent_end_time + delta_time, APP.justdo_grid_gantt.grid_gantt_column_width ) + 15
        line_end_y = gc._grid.getRowTopPosition( @getEventRow(e)) + e.offsetY
        
        p0 =
          x: independent_end_x
          y: independent_end_y
        
        p1 =
          x: line_end_x
          y: line_end_y
        
        $( ".temporary-dependency-line" ).remove();
        
        html = """<div class="temporary-dependency-line" style="#{APP.justdo_grid_gantt.lineStyle p0, p1};z-index: 1"></div>"""
        $(".justdo-grid-gantt-all-dependencies").append html
        
      return
  ]

  print: (doc, field, path) ->
    {grid_control, path, field} = @getFriendlyArgs()

    return ""
