_.extend JustdoGridGantt.prototype,
  
  _states_manager: {}
  
  getState: ->
    if (gc_id = APP.modules.project_page.gridControl()?.getGridUid())?
      if not (state = @_states_manager[gc_id])?
        state =
          task_id: null
          mouse_down:
            x: 0
            y: 0
            row: 0
          end_time:
            is_dragging: false # true when dragging a task end time
            original_time: 0  # cache if we need to restore
  
        @_states_manager[gc_id] = state
      return state
    return undefined
    
    