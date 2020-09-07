_.extend JustdoGridGantt.prototype,
  
  # Terminology:
  # If there are two tasks A and B where with finish-to-start dependency where task A has to finish
  # before task B starts (B.dependencies = [{task_id: A, dependency: F2S}] then we call
  # task A independent and task B is the dependent

  # Data structure
  #
  # We will define a dependency_key as <independent obj id>_<dependent obj id>_<dependency type>.
  # E.g: CpShJ9revNfFf6B8K_izRQTJEu3Jp2LaqEn_F2S
  #
  # We will define the following:
  #   dependencies_map will have the structure of:
  #                                               <dependency_key>:
  #                                                 <independent_rows>: [<row num>, ..] # grid rows where the task appears
  #                                                 <dependent_rows>: [<row num>, ..] # grid rows where the dependent appears
  #                                                 <independent> : <task_id>
  #                                                 <dependent> : <task_id>
  #                                                 <dependency_type>: <type>
  #
  #
  #   dependents_to_keys_set will have the structure of:
  #                                                <dependent_task_id>: Set() of dependency_keys
  #

  # Daniel - missing events to trigger a call to refreshArrows
  # - on refresh, at first the grid tree just presents the root tasks, and only after I process the dirty tasks
  #   more tasks are on the grid_tree, so I miss those.
  
  dependencies_map: {}
  dependents_to_keys_set: {}
  
  dependentId: (key) ->
    return key.split("_")[1]
  independentId: (key) ->
    return key.split("_")[0]
  dependencyType: (key) ->
    return key.split("_")[2]
    
  resetGanttDependencies: ->
    @dependencies_map = {}
    @dependents_to_keys_set = {}
    return
    
  addDependentTaskToGanttDependencies: (task_obj) ->
    if not (dependencies_mf = task_obj.justdo_task_dependencies_mf)?
      return
      
    self = @
    new_keys_set = new Set()
    for dependency in dependencies_mf
      new_keys_set.add "#{dependency.task_id}_#{task_obj._id}_#{dependency.type}"
  
    if (prev_keys_set = self.dependents_to_keys_set[task_obj._id])?
      # remove all keys that are not longer valid
      prev_keys_set.forEach (existing_key) ->
        if not new_keys_set.has existing_key
          delete self.dependencies_map[existing_key]
        return # end of forEach
    else
      prev_keys_set = new Set()
    
    # add all keys that are new
    new_keys_set.forEach (new_key) ->
      if not prev_keys_set.has new_key
        # todo: (optimization) mark this new entry for filling in the rows numbers
        self.dependencies_map[new_key] =
          independent_rows: []
          dependent_rows: []
          independent: self.independentId new_key
          dependent: self.dependentId new_key
          dependency_type: self.dependencyType new_key
          
      return # end of forEach
    
    self.dependents_to_keys_set[task_obj._id] = new_keys_set
    
    return
  
  resetDependenciesMapRowNumbers: ->
    self = @
    
    if not (gc = APP.modules.project_page.gridControl())?
      return
      
    indices = gc._grid_data._items_ids_map_to_grid_tree_indices
    
    for key, dependency_obj of self.dependencies_map
      dependency_obj.dependent_rows = indices[dependency_obj.dependent]
      dependency_obj.independent_rows = indices[dependency_obj.independent]
    return
  
  resetDependenciesDiv: ->
    Tracker.nonreactive =>
      if not (gc = APP.modules.project_page.gridControl())?
        return
      if gc._ready
        @_resetDependenciesDiv()
      else
        gc.once "ready", =>
          @_resetDependenciesDiv()
          return
      return
    return
  
  _resetDependenciesDiv: ->
    # todo: w/ Daniel - make reactive to all kinds of changes
    # todo: w/ Daniel - this function is called twice when changing views.
    self = @
    
    if not (gc = APP.modules.project_page.gridControl())?
      return
  
    $slick_view_port = $(".slick-viewport", gc.container)
    if not $slick_view_port.length
      return
      
    $overlay_div = $(".justdo-grid-gantt-all-dependencies", $slick_view_port)
    if $overlay_div.length
      $overlay_div.remove()
  
    grid_gantt_column_offset = 0
    column_found = false
    for column in gc.getView()
      if column.field != JustdoGridGantt.pseudo_field_id
        grid_gantt_column_offset += column.width
      else
        self.grid_gantt_column_width = column.width
        column_found = true
        break
    if not column_found
      return
      
    $slick_view_port.append """
      <div class="justdo-grid-gantt-all-dependencies"
            style="left: #{grid_gantt_column_offset}px; width: #{self.getColumnWidth()}px">
      </div>
      """
    
    self.refreshArrows()
    return
  
  renderDependency: (dependency_obj) ->
    self = @
    
    # todo - (optimization) use same tick cache for gc, epoch_range,
    if not (gc = APP.modules.project_page.gridControl())?
      return
    epoch_range = self.getEpochRange()
  
    for dependent_row in dependency_obj.dependent_rows or []
      if not (dependent_task_info = self.task_id_to_info[dependency_obj.dependent])?
        continue
      for independent_row in dependency_obj.independent_rows or []
        if not(independent_task_info = self.task_id_to_info[dependency_obj.independent])?
          continue
        if dependency_obj.dependency_type == "F2S"
          # numbers are references to the points calculation below
          # note that the dependent may appear above or below, and as well as before or after the independent
          #        [independent] 0--1
          #                         |
          #                         x
          #                         |
          #                  3---x--2
          #                  |
          #                  4--5 [dependent]
          #
          #
          if not (independent_end_time = independent_task_info.self_end_time)?
            if not (independent_end_time = independent_task_info.latest_child_end_time)?
              continue
          
          independent_end_x = self.timeOffsetPixels(epoch_range, independent_end_time, self.getColumnWidth())
          if independent_task_info.milestone_time?
            independent_end_x = independent_end_x + 5
          independent_end_y = gc._grid.getRowTopPosition(independent_row) + 15
          dependent_start_x = self.timeOffsetPixels epoch_range, dependent_task_info.self_start_time, self.getColumnWidth()
          if dependent_task_info.milestone_time?
            dependent_start_x = dependent_start_x - 5
          dependent_start_y = gc._grid.getRowTopPosition(dependent_row) + 15
          p0 =
            x: independent_end_x
            y: independent_end_y
          p1 =
            x: p0.x + 5
            y: p0.y
          p5 =
            x: dependent_start_x
            y: dependent_start_y
          p4 =
            x: p5.x - 8
            y: p5.y
          p2 =
            x: p1.x
            y: if p5.y > p0.y then (p5.y - 8) else (p5.y + 8)
          p3 =
            x: p4.x
            y: p2.y
          
          is_critical_path = self.isCriticalEdge dependency_obj.dependent, dependency_obj.independent

          # open point from code review https://github.com/justdoinc/justdo-internal-packages/commit/bc44b60fd490862549bb3065ea40ca9e37030943#r38823927
          html = """<div class="dependency-container #{if is_critical_path then "critical-path" else ""}" dependent-id="#{dependency_obj.dependent}" independent-id="#{dependency_obj.independent}"
                      dependency-type="#{dependency_obj.dependency_type}">"""
          html += """<div class="line horizontal al1" style="#{self.lineStyle p0, p1}"></div>"""
          if p1.x > 0 and p1.x < self.getColumnWidth()
            html += """<div class="line vertical al2" style="#{self.lineStyle p1, p2}">
                          <div class="dependency-1-2-cancel" style="top: #{(Math.abs(p1.y - p2.y) / 2)  - 14}px; left: -10px">
                            <svg class="jd-icon dependency-1-2-cancel-icon">
                              <use xlink:href="/layout/icons-feather-sprite.svg#x-circle"/>
                            </svg>
                          </div>
                      </div>"""
          html += """<div class="line horizontal al3" style="#{self.lineStyle p2, p3}"></div>"""
          if p3.x > 0 and p3.x < self.getColumnWidth()
            html += """<div class="line vertical al4" style="#{self.lineStyle p3, p4}"></div>"""
          html += """<div class="line horizontal al5" style="#{self.lineStyle p4, p5}"></div>"""
          if p5.x > 0 and p5.x < self.getColumnWidth()
            html += """<div class="right-arrow" style="top: #{p5.y - 3 }px; left: #{p5.x - 7}px"></div>"""
          html += "</div>"
          
          
          $(".justdo-grid-gantt-all-dependencies").append html
          
    return
  
  lineStyle: (p0, p1) ->
    # horizontal line
    self = @
    if p0.y == p1.y
      x0 = Math.min p0.x, p1.x
      x1 = Math.max p0.x, p1.x
      if x0 < 0 then x0 = 0
      if x0 > self.getColumnWidth() then x0 = self.getColumnWidth()
      if x1 < 0 then x1 = 0
      if x1 > self.getColumnWidth() then x1 = self.getColumnWidth()
      width = x1 - x0
      return "left: #{x0}px; top:#{p0.y}px; width:#{width}px;"
    # vertical line
    else if p0.x == p1.x
      return "left: #{p0.x}px; top:#{Math.min(p0.y, p1.y)}px; height: #{Math.abs(p1.y - p0.y) + 1}px"
    else
      thickness = 3
      x1 = p0.x
      y1 = p0.y
      
      x2 = p1.x
      y2 = p1.y
      
      # note about the -5 at the end - when adding a dependency, we identify a drop target based on the mouseenter
      # event into a specific div. There are situations in which the div that holds the line that we draw here is below
      # the mouse pointer, and then the browser dose not identify the target div. making the line shorter (by 5 pixels)
      # solves this issue.
      # Daniel - there are extreme situation that this solution doesn't cover. Need to speak.
      length = Math.sqrt(((x2-x1) * (x2-x1)) + ((y2-y1) * (y2-y1))) - 5
    
      #center
      cx = ((x1 + x2) / 2) - (length / 2)
      cy = ((y1 + y2) / 2) - (thickness / 2)
      
      angle = Math.atan2((y1-y2),(x1-x2))*(180/Math.PI);
      return """
             padding:0px; margin:0px; height: #{thickness}px; background-color: red; line-height:1px; position:absolute;
             left: #{cx}px; top: #{cy}px; width: #{length}px;
             -moz-transform:rotate(#{angle}deg); -webkit-transform:rotate(#{angle}deg); -o-transform:rotate(#{angle}deg);
             -ms-transform:rotate(#{angle}deg); transform:rotate(#{angle}deg);
      """
    return ""
    
  rerenderAllDependencies: ->
    self = @

    # remove all existing arrows
    gc_id = APP.modules.project_page.gridControl().getGridUid()
    $gc_id = $(".#{gc_id}")
    $(".justdo-grid-gantt-all-dependencies .dependency-container", $gc_id).remove()
    
    # add dependencies one by one
    for dependency_key, dependency_obj of self.dependencies_map
      self.renderDependency dependency_obj
    return
  
  renderTodayIndicator: ->    
    self = @

    # todo - (optimization) use same tick cache for gc, epoch_range,
    if not (gc = APP.modules.project_page.gridControl())?
      return

    epoch_range = self.getEpochRange()
    
    today_0000 = moment().startOf("day").add(moment().utcOffset(), "minutes").valueOf()
    if (offset = self.timeOffsetPixels(epoch_range, today_0000, self.getColumnWidth()))? and
      0 < offset and offset < self.getColumnWidth()
        p0 =
          x: offset
          y: 0
        p1 =
          x: offset
          y: $(".grid-control-tab.active .grid-canvas").outerHeight()

        html = """
                <div class="dependency-container">
                  <div class="line vertical today-indicator" style="#{self.lineStyle p0, p1}">
                  </div>
                </div>
                """

        $(".justdo-grid-gantt-all-dependencies").append html

  daily_refresh_timeout: null

  _refreshArrows: ->
    self = @
    # Refresh daily
    if self.daily_refresh_timeout?
      Meteor.clearTimeout self.daily_refresh_timeout
    self.daily_refresh_timeout = Meteor.setTimeout ->
      self._refreshArrows()
    , moment().startOf("day").add(1, "day") - moment()

    # The following happens when a core data is done loading, but the grid itself is  not populated yet.
    if _.isEmpty(@task_id_to_info)
      return
    if not (gc = APP.modules.project_page.gridControl())?
      return
    
    @resetGanttDependencies()
    
    for row in gc._grid_data.grid_tree
      task_obj = row[0]
      if task_obj.justdo_task_dependencies_mf?
        @addDependentTaskToGanttDependencies task_obj
    
    @resetDependenciesMapRowNumbers()
    # todo with Daniel - this resetDependenciesDiv should not  be called here, however, I couldn't find the right
    # place to put it. See Task #7645: hints are removed frequently on mouse move. See comment in _refreshArrows()
    # @resetDependenciesDiv()
    @rerenderAllDependencies()

    @renderTodayIndicator()
    
    return

  refreshArrows: (options) ->
    if not options?
      options = {}
    
    {defer} = options

    if defer
      Meteor.defer =>
        @_refreshArrows()
        return
    else
      @_refreshArrows()

    return
  
  refreshDependenciesCanvas: ->
    @resetDependenciesDiv()
    @refreshArrows()

    return
    
    