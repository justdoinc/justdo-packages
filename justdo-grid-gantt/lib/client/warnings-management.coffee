_.extend JustdoGridGantt.prototype,
  # This is the object  that will manage all the warnings checking, registration and servings
  
  warnings_manager:
  
    _warnings: {}                     # Data structure:
                                      #   <task_id>: Set of warning_types
  
    _warning_types_to_message:
      "start_gt_end": "Task's Start time is greater than End time"

    hasWarnings: (task_id) ->
      if @_warnings?[task_id]?.size > 0
        return true
      return false
      
      
    getHumanReadableWarnings: (task_id) ->
      if not (warnings = @_warnings[task_id])?
        return []
      ret = []
      warnings.forEach (warning) =>
        ret.push @_warning_types_to_message[warning]
        return
      return ret
      
    checkTask: (task_obj) ->
      
      if not (warnings_set = @_warnings[task_obj._id])?
        warnings_set = new Set()
        @_warnings[task_obj._id] = warnings_set
      
      if task_obj.start_date? and task_obj.end_date? and task_obj.start_date > task_obj.end_date
        warnings_set.add "start_gt_end"
      else
        warnings_set.delete "start_gt_end"
      return
      
    checkTasksDependencies: (task_obj) ->
      # todo..
      # since we don't have the parents objects handy, this might take a long time for big projects. consider lazy load.
      return
      
    removeTask: (task_id) ->
      delete @_warnings[task_id]
      return
    
    