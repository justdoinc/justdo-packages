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
      
    self = APP.justdo_grid_gantt
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
        # todo: mark this new entry for filling in the rows numbers
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
    if not (gc = APP.modules.project_page.gridControl())?
      return
    indices = gc._grid_data._items_ids_map_to_grid_tree_indices
    self = APP.justdo_grid_gantt
    for key, dependency_obj of self.dependencies_map
      dependency_obj.dependent_rows = indices[dependency_obj.dependent]
      dependency_obj.independent_rows = indices[dependency_obj.independent]
    return
    
  resetDependenciesDiv: ->
    # todo: (w/ Daniel - make reactive to all kinds of changes
    self = APP.justdo_grid_gantt
    if not (gc = APP.modules.project_page.gridControl())?
      return
      
    if $(".justdo-grid-gantt-all-dependencies").length
      $(".justdo-grid-gantt-all-dependencies").remove()
  
    $slick_view_port = $(".slick-viewport")
    if not $slick_view_port.length
      return

    grid_gantt_column_offset = 0
    
    for column in gc.getView()
      if column.field != "justdo_grid_gantt"
        grid_gantt_column_offset += column.width
        self.grid_gantt_column_index += 1
      else
        self.grid_gantt_column_width = column.width
        break
    if self.grid_gantt_column_width == -1
      self.grid_gantt_column_index = -1
      return
      
    $slick_view_port.append """
      <div class="justdo-grid-gantt-all-dependencies"
            style="left: #{grid_gantt_column_offset}px; width: #{self.grid_gantt_column_width}px">
      </div>
      """

    return
  
  renderDependency: (dependency_obj) ->
    self = APP.justdo_grid_gantt
  
    # todo - use same tick cache for gc, epoch_range,
    if not (gc = APP.modules.project_page.gridControl())?
      return
    epoch_range = [
      self.gantt_coloumn_from_epoch_time_rv.get(),
      self.gantt_coloumn_to_epoch_time_rv.get()
    ]
  
    for dependent_row in dependency_obj.dependent_rows
      dependent_box = gc._grid.getCellNodeBox dependent_row, self.grid_gantt_column_index
      dependent_task_info = self.task_id_to_info[dependency_obj.dependent]
      for independent_row in dependency_obj.independent_rows
        independent_box = gc._grid.getCellNodeBox  independent_row, self.grid_gantt_column_index
        independent_task_info = self.task_id_to_info[dependency_obj.independent]
        if dependency_obj.dependency_type == "F2S"
          # numbers are references to the points calculation below
          # note that the dependent may appear above or below, and as well as before or after the independent
          #        [independent] 0--1
          #                         |
          #                  3------2
          #                  |
          #                  4--5 [dependent]
          #
          #
          independent_end_x = self.timeOffsetPixels(epoch_range, independent_task_info.self_end_time, self.grid_gantt_column_width )
          independent_end_y = gc._grid.getRowTopPosition(independent_row) + 15
          dependent_start_x = self.timeOffsetPixels(epoch_range, dependent_task_info.self_start_time, self.grid_gantt_column_width )
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
          
          html = """<div class="dependency-container">"""
          html += """<div class="line" style="#{self.lineStyle p0, p1}"></div>"""
          if p1.x > 0 and p1.x < self.grid_gantt_column_width
            html += """<div class="line" style="#{self.lineStyle p1, p2}"></div>"""
          html += """<div class="line" style="#{self.lineStyle p2, p3}"></div>"""
          if p3.x > 0 and p3.x < self.grid_gantt_column_width
            html += """<div class="line" style="#{self.lineStyle p3, p4}"></div>"""
          html += """<div class="line" style="#{self.lineStyle p4, p5}"></div>"""
          if p5.x > 0 and p5.x < self.grid_gantt_column_width
            html += """<div class="right-arrow" style="top: #{p5.y - 3 }px; left: #{p5.x - 7}px"></div>"""
          html += "</div>"
          
          
          $(".justdo-grid-gantt-all-dependencies").append html
          
    return
  
  lineStyle: (p0, p1) ->
    # horizontal line
    self = APP.justdo_grid_gantt
    if p0.y == p1.y
      x0 = Math.min p0.x, p1.x
      x1 = Math.max p0.x, p1.x
      if x0 < 0 then x0 = 0
      if x0 > self.grid_gantt_column_width then x0 = self.grid_gantt_column_width
      if x1 < 0 then x1 = 0
      if x1 > self.grid_gantt_column_width then x1 = self.grid_gantt_column_width
      width = x1 - x0
      return "left: #{x0}px; top:#{p0.y}px; width:#{width}px; height: 1px"
    # vertical line
    else if p0.x == p1.x
      return "left: #{p0.x}px; top:#{Math.min(p0.y, p1.y)}px; width: 1px; height: #{Math.abs(p1.y - p0.y) + 1}px"
    else
      console.error "grid-gantt line type not supported"
    return ""
    
  rerenderAllDependencies: ->
    self = APP.justdo_grid_gantt
    
    if self.grid_gantt_column_index < 0
      return
      
    # remove all existing arrows
    $(".justdo-grid-gantt-all-dependencies").empty()
    
    # add dependencies one by one
    for dependency_key, dependency_obj of self.dependencies_map
      self.renderDependency dependency_obj
    return
    
  refreshArrows: (from_line, to_line) ->
    if not (gc = APP.modules.project_page.gridControl())?
      return
    
    @resetGanttDependencies()
    
    for row in gc._grid_data.grid_tree
      task_obj = row[0]
      if task_obj.justdo_task_dependencies_mf?
        @addDependentTaskToGanttDependencies task_obj
    
    @resetDependenciesMapRowNumbers()
    @resetDependenciesDiv()
    @rerenderAllDependencies()
    
    
    return
  