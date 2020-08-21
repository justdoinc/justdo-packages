_.extend JustdoGridGantt.prototype,
  getOrCreateState: ->
    if (gc_id = APP.modules.project_page.gridControl()?.getGridUid())?
      if not (state = @_states_manager[gc_id])?
        state =
          task_id: null
          mouse_down:
            x: 0
            y: 0
            row: 0
          main_bar:
            is_dragging: false
            original_start_time: 0
            original_end_time: 0
          end_time:
            is_dragging: false # true when dragging a task end time
            original_end_time: 0  # cache if we need to restore
            original_start_time: 0
          milestone:
            is_dragging: false
            original_milestone_time: 0
          due_time:
            is_dragging: false
            original_due_time: 0
          dependencies:
            finish_to_x_independent: null
            independent_end_time: 0
          column_range:  # use to drag the column content left and right to control its range
            is_dragging: false
            original_from_epoch_time: 0
            original_to_epoch_time: 0
        @_states_manager[gc_id] = state
      return state
    return undefined
    
  setState: (options) ->
    if (state = @getOrCreateState())?
      _.extend state, options
    return
    
  
  resetStatesChangeOnEscape: ->
    states = @getOrCreateState()
    
    if states.end_time.is_dragging
      states.end_time.is_dragging = false
      APP.justdo_grid_gantt.setPresentationEndTime states.task_id, states.end_time.original_end_time
      states.task_id = null
  
    if states.milestone.is_dragging
      states.milestone.is_dragging = false
      APP.justdo_grid_gantt.setPresentationMilestone states.task_id, states.milestone.original_milestone_time
      states.task_id = null
    
    if states.due_time.is_dragging
      states.due_time.is_dragging = false
      APP.justdo_grid_gantt.setPresentationDueTime states.task_id, states.due_time.original_due_time
      states.task_id = null
      
    if states.main_bar.is_dragging
      states.main_bar.is_dragging = false
      APP.justdo_grid_gantt.setPresentationStartTime states.task_id, states.main_bar.original_start_time
      APP.justdo_grid_gantt.setPresentationEndTime states.task_id, states.main_bar.original_end_time
      states.task_id = null
  
    if states.dependencies.finish_to_x_independent?
      states.dependencies.finish_to_x_independent = null
      $(".temporary-dependency-line").remove()
      
    return
    
    
    
    